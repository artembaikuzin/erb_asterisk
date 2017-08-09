module ErbAsterisk
  module FileCache
    def file_read(file_name)
      content = @file_cache[file_name]
      if content
        log_debug('cache', 3)
        return content
      end

      content = File.read(file_name)
      @file_cache[file_name] = content

      log_debug('disk', 3)

      content
    end

    def file_exist?(file_name)
      return true if @file_cache.key?(file_name)
      File.exist?(file_name)
    end

    def file_cache_init
      @file_cache = {}
    end
  end
end
