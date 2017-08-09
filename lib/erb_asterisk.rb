require 'erb'
require 'find'
require 'pathname'

require 'erb_asterisk/render'
require 'erb_asterisk/inclusion'
require 'erb_asterisk/yields'
require 'erb_asterisk/utils'

module ErbAsterisk
  include Render
  include Inclusion
  include Yields
  include Utils

  def execute(opts)
    init_instance(opts)
    load_project_file

    root = asterisk_root
    @templates_path = "#{root}templates".freeze

    render_files(root)
    export_includes(root)
  end

  private

  ERB_PROJECT_FILE = './erb_asterisk_project.rb'.freeze
  ERB_ASTERISK_CONF = 'asterisk.conf'.freeze
  ERB_ASTERISK_DIR = 'asterisk/'.freeze

  def init_instance(opts)
    @exports = {}
    @templates_path = ''
    @yields = {}

    user_path = opts[:templates].nil? ? '~/.erb_asterisk' : opts[:templates]
    @user_templates = File.expand_path("#{user_path}/templates")
  end

  def asterisk_root
    return './' if File.exist?(ERB_ASTERISK_CONF)
    return ERB_ASTERISK_DIR if Dir.exist?(ERB_ASTERISK_DIR)
    raise 'Asterisk configuration not found'
  end

  def load_project_file
    require ERB_PROJECT_FILE if File.exist?(ERB_PROJECT_FILE)
  end

  def render_files(root)
    erbs = load_erbs(root)

    # It does two round of rendering because of apply_line_to and yield_here.
    # First round accumulates apply_line_to declarations and converts
    # yield_here to yield_actual.
    render_erbs(erbs)
    # Second round replaces yield_actual with accumulated apply_line_to.
    render_erbs(erbs)

    save_erbs(erbs)
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
      # Declare global variable with current erb file name for include_to method:
      TOPLEVEL_BINDING.local_variable_set(:current_conf_file, value[:config])
      erbs[file][:content] = new_erb(value[:content]).result
    end
  end

  def save_erbs(erbs)
    erbs.each { |_, value| File.write(value[:config], value[:content]) }
  end

  def export_includes(root)
    @exports.each do |include_file, content|
      content = content.sort_by { |i| -i[:priority] }
      result = content.reduce('') do |s, i|
        s << "; priority: #{i[:priority]}\n" if i[:priority] != 0
        s << "#include \"#{i[:file].sub(root, '')}\"\n"
      end

      File.write("#{root}#{include_file}", result)
    end
  end

  def read_template(template)
    file_name = "#{template}.erb"
    project_template = "#{@templates_path}/#{file_name}"
    return File.read(project_template) if File.exist?(project_template)

    user_template = "#{@user_templates}/#{file_name}"
    return File.read(user_template) if File.exist?(user_template)

    raise "Template not found: #{template}"
  end

  def new_erb(content)
    ERB.new(content, nil, '-', '@erb_output')
  end

  def default_args!(args)
    args[:priority] = 0 if args[:priority].nil?
  end
end
