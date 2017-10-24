require 'slop'
require 'erb_asterisk/version'

module ErbAsterisk
  class ArgParser
    def execute
      Slop.parse do |o|
        o.banner = 'usage: erb_asterisk [options] [asterisk_config_path]'

        o.string '-t', '--templates',
                 'set templates path (e.g.: ~/.erb_asterisk)'
        o.bool '-v', '--verbose', 'enable verbose mode'

        o.on '--version', 'print the version' do
          puts "#{VERSION}"
          exit
        end

        o.on '-h', '--help', 'print this help' do
          puts o
          exit
        end
      end
    end
  end
end
