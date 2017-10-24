require 'erb'
require 'find'
require 'pathname'

require 'erb_asterisk/render'
require 'erb_asterisk/inclusion'
require 'erb_asterisk/yields'
require 'erb_asterisk/utils'
require 'erb_asterisk/log'
require 'erb_asterisk/file_cache'
require 'erb_asterisk/soft_write'

module ErbAsterisk
  include Render
  include Inclusion
  include Yields
  include Utils
  include Log
  include FileCache
  include SoftWrite

  def execute(opts)
    init_instance(opts)
    load_project_file

    root = asterisk_root(opts)
    @templates_path = "#{root}templates".freeze

    render_files(root)
  end

  private

  ERB_PROJECT_FILE = './erb_asterisk_project.rb'.freeze
  ERB_ASTERISK_CONF = 'asterisk.conf'.freeze
  ERB_ASTERISK_DIR = 'asterisk/'.freeze

  def init_instance(opts)
    @exports = {}
    @templates_path = ''
    @yields = {}

    log_init(opts[:verbose])
    file_cache_init

    user_path = opts[:templates].nil? ? '~/.erb_asterisk' : opts[:templates]
    @user_templates = File.expand_path("#{user_path}/templates")
  end

  def asterisk_root(opts)
    return "#{opts.arguments.first}/" if opts.arguments.any?
    return './' if File.exist?(ERB_ASTERISK_CONF)
    return ERB_ASTERISK_DIR if Dir.exist?(ERB_ASTERISK_DIR)
    raise 'Asterisk configuration not found'
  end

  def load_project_file
    require ERB_PROJECT_FILE if File.exist?(ERB_PROJECT_FILE)
  end

  def render_files(root)
    erbs = load_erbs(root)

    if erbs.empty?
      log_debug('nothing to do')
      return
    end

    # It does two round of rendering because of apply_line_to and yield_here.
    # First round accumulates apply_line_to declarations and converts
    # yield_here to yield_actual.
    log_debug('FIRST ROUND:')
    render_erbs(erbs)
    log_debug('')

    # Second round replaces yield_actual with accumulated apply_line_to.
    log_debug('SECOND ROUND:')
    render_erbs(erbs)
    log_debug('')

    save_configs(erbs)
    export_includes(root)
  end

  def load_erbs(root)
    erbs = {}

    Find.find(root) do |f|
      next if File.directory?(f)
      next if f.start_with?(@templates_path)
      next unless f.end_with?('.erb')

      erbs[f] = { config: f.chomp('.erb'),
                  content: File.read(f) }
    end

    erbs
  end

  def render_erbs(erbs)
    erbs.each do |file, value|
      # Skip on second round all erbs without yield_here method
      next if value[:skip]

      # Declare variable with current erb file name for include_to method:
      @current_conf_file = value[:config]
      log_debug("ERB: #{file}", 1)

      @yield_here_occured = false
      value[:content] = new_erb(value[:content]).result
      value[:skip] = true unless @yield_here_occured
    end
  end

  def save_configs(erbs)
    erbs.each do |_, value|
      config = value[:config]
      next unless soft_write(config, value[:content])
      log_debug("save_configs: #{config}")
    end
  end

  def export_includes(root)
    @exports.each do |include_file, content|
      content = content.sort_by { |i| -i[:priority] }
      result = content.reduce('') do |s, i|
        s << "; priority: #{i[:priority]}\n" if i[:priority] != 0
        s << "#include \"#{i[:file].sub(root, '')}\"\n"
      end

      f = "#{root}#{include_file}"
      next unless soft_write(f, result)
      log_debug("export_includes: #{f}")
    end
  end

  def read_template(template)
    file_name = "#{template}.erb"
    project_template = "#{@templates_path}/#{file_name}"
    if file_exist?(project_template)
      log_debug("read_template: #{project_template}", 2)
      return file_read(project_template)
    end

    user_template = "#{@user_templates}/#{file_name}"
    if file_exist?(user_template)
      log_debug("read_template: #{user_template}", 2)
      return file_read(user_template)
    end

    raise "Template not found: #{template}"
  end

  def new_erb(content)
    ERB.new(content, nil, '-', '@erb_output')
  end

  def default_args!(args)
    args[:priority] = 0 if args[:priority].nil?
  end
end
