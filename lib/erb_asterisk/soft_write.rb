require 'digest'

module ErbAsterisk
  module SoftWrite
    # Write to file only if something has changed
    def soft_write(file_name, content)
      if !File.exist?(file_name) ||
         Digest::MD5.hexdigest(File.read(file_name)) !=
         Digest::MD5.hexdigest(content)
        File.write(file_name, content)
        return true
      end

      false
    end
  end
end
