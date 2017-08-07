require 'erb'
require 'find'
require 'pathname'

module ErbAsterisk
  # Render template
  def render(template, vars = {})
    tpl = read_template(template)
    e = ERB.new(tpl)

    b = TOPLEVEL_BINDING
    vars.each do |name, value|
      b.local_variable_set(name, value)
    end

    e.result
  end

  # Declare current config file inclusion to file_name
  # args can has :priority key (larger the number - higher the priority)
  def include_to(file_name, args = {})
    return unless TOPLEVEL_BINDING.local_variable_defined?(:current_conf_file)
    args = { priority: 0 }.merge(args)
    @exports[file_name] = [] if @exports[file_name].nil?

    arr = @exports[file_name]

    current_conf_file = TOPLEVEL_BINDING.local_variable_get(:current_conf_file)
    unless arr.index { |i| i[:file] == current_conf_file }.nil?
      puts "Skip #{current_conf_file} duplicate inclusion to #{file_name}"
      return
    end

    arr << { file: current_conf_file, priority: args[:priority] }
    "; Included to \"#{file_name}\""
  end

  # Apply line to place where yield_here :tag defined
  def apply_line_to(tag, line)
    if @yields[tag].nil?
      @yields[tag] = line
    else
      @yields[tag] << "\n#{line}"
    end

    "; Applied \"#{line}\" to :#{tag}"
  end

  # Define place where put apply_line_to
  def yield_here(tag)
    "<%= yield_actual :#{tag} %>"
  end

  def yield_actual(tag)
    "; Yield for :#{tag}\n" << @yields[tag]
  end

  # Escape special symbols in extension name
  #
  # vnov -> v[n]on
  # LongExtension1234! -> Lo[n]gE[x]te[n]sio[n]1234[!]
  #
  def escape_exten(exten)
    exten.each_char.reduce('') do |s, c|
      s << (ERB_ASTERISK_PATTERNS.include?(c.downcase) ? "[#{c}]" : c)
    end
  end

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
  ERB_ASTERISK_PATTERNS = %w(x z n . !)

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
      erbs[file][:content] = ERB.new(value[:content]).result
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
end
