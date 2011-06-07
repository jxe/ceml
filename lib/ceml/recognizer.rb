module CEML
  class Recognizer
    def self.recognize msg
      return :yes if msg == 'y' || msg =~ /^yes/i
      return :abort if msg == 'abort'
      return :done if msg =~ /^done/i || msg == 'd'
    end
  end
end
