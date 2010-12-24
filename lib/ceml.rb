require 'forwardable'
require 'treetop'

require 'ceml/casting'
require 'ceml/instructions'
require 'ceml/script'
require 'ceml/tt/lexer'
require 'ceml/tt/casting'
require 'ceml/tt/instructions'
require 'ceml/tt/scripts'

require 'ceml/incident'

module CEML
  extend self
  attr_accessor :delegate
  @delegate = Class.new{ def method_missing(meth, *args, &blk);end }.new
  # puts "#{meth}: #{args.to_s.inspect}"
end

class CEML::ScriptsParser
  def parse_with_root(string, root)
    self.root = root
    parse(string)
  end
end

module CEML
  def parse(what, string)
    result = nil
    string.gsub!(/\n +/, ' ')
    string << "\n"
    ScriptsParser.new.tap do |parser|
      result = parser.parse_with_root(string, what)
      raise "parse failed: \n#{parser.failure_reason}" unless result
      case what
      when :scripts
        raise "no scripts found" unless result.elements and !result.elements.empty?
        result = result.elements
        result.each{ |s| s.validate! }
      when :script
        result.validate!
      end
    end
    result
  end
end
