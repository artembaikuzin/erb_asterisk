require 'erb'
require 'find'
require 'pathname'

module ErbAsterisk
  # Render template
  def render(template, vars = {})
    tpl = File.read("#{@templates}/#{template}.erb")
    e = ERB.new(tpl)

    b = TOPLEVEL_BINDING
    vars.each do |name, value|
      b.local_variable_set(name, value)
    end

    e.result
  end

  # Declare current config file inclusion to file_name
  def include_to(file_name)
    return unless TOPLEVEL_BINDING.local_variable_defined?(:current_conf_file)
    @exports[file_name] = [] if @exports[file_name].nil?
    arr = @exports[file_name]

    current_conf_file = TOPLEVEL_BINDING.local_variable_get(:current_conf_file)
    if arr.include?(current_conf_file)
      puts "Skip #{current_conf_file} duplicate inclusion to #{file_name}"
      return
    end

    arr << current_conf_file
    "; Included to \"#{file_name}\""
  end

  def execute
    init_instance
    load_project_file

    root = asterisk_root
    @templates = "#{root}templates".freeze

    render_files(root)
    export_includes(root)
  end

  private

  ERB_PROJECT_FILE = './erb_asterisk_project.rb'.freeze
  ERB_ASTERISK_CONF = 'asterisk.conf'.freeze
  ERB_ASTERISK_DIR = 'asterisk/'.freeze

  def init_instance
    @exports = {}
    @templates = ''
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
    Find.find(root) do |f|
      next if File.directory?(f)
      next if f.start_with?(@templates)
      next unless f.end_with?('.erb')

      output_config = f.chomp('.erb')

      TOPLEVEL_BINDING.local_variable_set(:current_conf_file,
                                          output_config.sub(root, ''))

      File.write(output_config, ERB.new(File.read(f)).result)
    end
  end

  def export_includes(root)
    @exports.each do |include_file, content|
      s = ''
      content.each do |file|
        s << "#include \"#{file}\"\n"
      end

      File.write("#{root}#{include_file}", s)
    end
  end
end
