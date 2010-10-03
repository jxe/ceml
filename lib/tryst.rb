require 'benchmark'
require 'forwardable'
require 'treetop'

require 'tryst/casting'
require 'tryst/instructions'
require 'tryst/script'
require 'tryst/tt/lexer'
require 'tryst/tt/casting'
require 'tryst/tt/instructions'
require 'tryst/tt/scripts'

require 'tryst/coordinator'
require 'tryst/engine'

module Tryst
  def parse(what, string)
    result = nil
    time = Benchmark.realtime do
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
    end
    puts "Script parsed in #{time}s" unless time < 0.01
    result
  end

  extend self
end
