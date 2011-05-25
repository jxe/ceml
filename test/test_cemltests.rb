require 'ceml'
require 'test/helper'
require 'set'

class TestCemlTests < Test::Unit::TestCase

  def setup
    CEML::Queue.new.calls.clear
  end

  def test_cemltests
    Dir["test/*.cemltest"].each do |f|
      name = File.basename(f, '.cemltest')
      scripts = File.new("test/#{name}.ceml").read
      test    = File.new(f).read

      puts "Running cemltest #{name}..."

      s = CEML.parse(:scripts, scripts).map(&:castable)
      bundle_id = s.hash.to_s
      CEML::Processor.set_bundle(bundle_id, s)
      CEML::Processor.reset_bundle(bundle_id)
      pl = Set.new
      play do
        test.each_line do |line|
          puts ">>>> #{line}"
          case line.strip
          when /^(\w+) *< *(.*)$/
            if $2.empty?
              silent $1
            else
              told $1, /#{$2}/
            end
          when /^(\w+) *> *(.*)$/
            player_id, msg = $1, $2
            player = {:id => player_id, :received => msg }
            if !pl.include?(player_id)
              player[:tags] = ['new']
              pl << player_id
            end
            player[:recognized] = :yes if msg == 'y' || msg =~ /^yes/i
            player[:recognized] = :abort if msg == 'abort'
            player[:recognized] = :done if msg =~ /^done/i || msg == 'd'
            CEML::Processor.ping(bundle_id, player)
            CEML::Processor.run
          when /^\((\d+)\s*(\w+)\)$/
            CEML.incr_clock CEML.dur($1.to_i, $2)
            CEML::Processor.run_latest
            CEML::Processor.run
          when /^#/
          else "Skipping line #{line}..."
          end
        end
      end
    end
  end

end
