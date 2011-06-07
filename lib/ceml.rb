require 'forwardable'

require 'ceml/models'
require 'ceml/lang'
require 'ceml/recognizer'
require 'ceml/processor'
require 'stringio'

module CEML
  extend self
  @extra_seconds = 0
  @log_io = STDERR
  attr_reader :tells
  def clock; Time.now.utc.to_i + @extra_seconds; end
  def incr_clock(s); @extra_seconds += s; end
  def dur(n, unit)
    n * case unit
    when /^h/; 60*60; when /^mi/; 60; else 1; end
  end

  def capture_log
    log = ""
    err = nil
    prev_io, @log_io = @log_io, StringIO.new(log)
    yield
  rescue Exception => err
    @log_io.puts "\nERROR: #{err}\n\n\n"
  ensure
    @log_io = prev_io
    return err, log
  end

  def log lvl, msg
    if lvl > 1
      msg = "    #{msg}"
    end
    @log_io.puts msg
  end
end

module CEML
  def parse(what, string)
    string = string.dup
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

  def test test, p = CEML::Processor
    scripts, test = test.split("\n---\n")
    s = CEML.parse(:scripts, scripts).map(&:castable)
    bundle_id = gen_code # s.hash.to_s
    @tells = Hash.new{ |h,k| h[k] = [] }
    p.set_bundle(bundle_id, s)
    p.reset_bundle(bundle_id)
    pl = Set.new
    CEML.capture_log do
      test.each_line do |line|
        line = line.strip
        next if line =~ /^#/ or line =~ /^\s*$/
        CEML.log 1, "#{line}"
        case line
        when /^(\w+) *< *(.*)$/
          player_id, msg = $1, $2
          heard = tells[player_id].shift
          next if msg.empty? and !heard
          raise "Expected silence from #{player_id}, got #{heard}" if msg.empty? and heard
          raise "Expected #{player_id} < #{msg}, got silence" if !msg.empty? and !heard
          heard = (heard||={})[:msg] || (heard||={})[:q] || ''
          raise "Expected #{player_id} < #{msg}, got #{heard}" unless heard =~ /#{msg}/
          next
        when /^(\w+) *> *(.*)$/
          player_id, msg = $1, $2
          player = {:id => player_id, :received => msg }
          if !pl.include?(player_id)
            player[:tags] = ['new']
            p.reset_player(bundle_id, player_id)
            pl << player_id
          end
          player[:recognized] = CEML::Recognizer.recognize(msg)
          p.ping(bundle_id, player)
        when /^\((\d+)\s*(\w+)\)$/
          CEML.incr_clock CEML.dur($1.to_i, $2)
          p.run_latest
        end
        p.run
      end
    end
  end
end
