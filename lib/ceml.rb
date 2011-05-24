require 'forwardable'

require 'ceml/models'
require 'ceml/lang'
require 'ceml/processor'

module CEML
  extend self
  @extra_seconds = 0
  def clock; Time.now.utc.to_i + @extra_seconds; end
  def incr_clock(s); @extra_seconds += s; end
  def dur(n, unit)
    n * case unit
    when /^h/; 60*60; when /^mi/; 60; else 1; end
  end
end

module CEML
  def parse(what, string)
    string = string.dup
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
