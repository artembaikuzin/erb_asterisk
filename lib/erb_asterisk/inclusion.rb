module ErbAsterisk
  module Inclusion
    # Declare current config file inclusion to file_name
    # args can has :priority key (larger the number - higher the priority)
    def include_to(file_name, args = {})
      return unless TOPLEVEL_BINDING.local_variable_defined?(:current_conf_file)
      default_args!(args)
      @exports[file_name] = [] if @exports[file_name].nil?

      arr = @exports[file_name]

      current_conf_file = TOPLEVEL_BINDING.local_variable_get(:current_conf_file)
      unless arr.index { |i| i[:file] == current_conf_file }.nil?
        log_warn(
          "Skip #{current_conf_file} duplicate inclusion to #{file_name}")
        return
      end

      log_debug("include_to: #{current_conf_file}, #{file_name}, #{args}", 2)

      arr << { file: current_conf_file, priority: args[:priority] }
      "; Included to \"#{file_name}\""
    end
  end
end
