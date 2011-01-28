require 'forwardable'
require 'treetop'

require 'ceml/script'
require 'ceml/casting_statement'
require 'ceml/instruction_statements'
require 'ceml/tt/lexer'
require 'ceml/tt/casting'
require 'ceml/tt/instructions'
require 'ceml/tt/scripts'

require 'ceml/role'
require 'ceml/confluence'
require 'ceml/incident'
require 'ceml/driver'

module CEML
  extend self
end

module CEML
  def parse(what, string)
    string.gsub!(/\n +/, ' ')
    what = case what
    when :script then :free_script
    when :scripts then :free_scripts
    else what
    end
    result = nil
    ScriptsParser.new.tap do |parser|
      result = parser.parse(string, :root => what)
      raise "parse failed: \n#{parser.failure_reason}" unless result
      case what
      when :free_scripts
        raise "no scripts found" unless result.scripts.list
        result = result.scripts.list
        result.each{ |s| s.validate! }
      when :free_script
        result = result.script
        result.validate!
      end
    end
    result
  end
end
