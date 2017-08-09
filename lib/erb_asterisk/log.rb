require 'logger'

module ErbAsterisk
  module Log
    private

    def log_init(verbose)
      @log = Logger.new(STDOUT)
      @log.level = verbose ? Logger::DEBUG : Logger::WARN
    end

    def log_debug(msg, level = 0)
      @log.debug { "#{'  ' * level}#{msg}" }
    end

    def log_warn(msg)
      @log.warn { msg }
    end
  end
end
