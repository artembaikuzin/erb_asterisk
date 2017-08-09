module ErbAsterisk
  module Utils
    # Escape special symbols in extension name
    #
    # vnov -> v[n]on
    # LongExtension1234! -> Lo[n]gE[x]te[n]sio[n]1234[!]
    #
    def escape_exten(exten)
      exten.each_char.reduce('') do |s, c|
        s << (%w(x z n . !).include?(c.downcase) ? "[#{c}]" : c)
      end
    end
  end
end
