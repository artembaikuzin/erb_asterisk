module ErbAsterisk
  module Render
    # Render template
    def render(template, vars = {})
      log_debug("render: #{template}", 2)

      old_erb_output = @erb_output
      @erb_output = ''

      erb = new_erb(read_template(template))

      b = binding
      vars.each do |name, value|
        b.local_variable_set(name, value)
      end

      r = erb.result(b)
      @erb_output = old_erb_output
      r
    end
  end
end
