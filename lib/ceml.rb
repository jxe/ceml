require 'forwardable'
require 'treetop'

require 'ceml/casting'
require 'ceml/instructions'
require 'ceml/script'
require 'ceml/tt/lexer'
require 'ceml/tt/casting'
require 'ceml/tt/instructions'
require 'ceml/tt/scripts'

require 'ceml/engine'

module CEML
  def parse(what, string)
    result = nil
    string.gsub!(/\n +/, ' ')
    string << "\n"
    p = ScriptsParser.new
    p.root = what
    result = p.parse(string)
    raise "parse failed: \n#{p.failure_reason}" unless result
    case what
    when :scripts
      raise "no scripts found" unless result.elements and !result.elements.empty?
      result = result.elements
      result.each{ |s| s.validate! }
    when :script
      result.validate!
    end
    result
  end

  extend self
end
