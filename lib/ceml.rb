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
