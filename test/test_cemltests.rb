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
      scripts = File.new("test/#{name}.ceml")).read
      test    = File.new(f).read

      puts "Running cemltest #{name}..."

      s = scriptfam(scripts)
      pl = Set.new
      play do
        test.each_line do |line|
          case line.trim
          when /^(\w+) *< *(.*)$/
            if $2.empty? then silent $1 else told $1, /#{$2}/ end
          when /^(\w+) *> *(.*)$/
            if pl.include?($1) then says $1, $2
            else ping s, :id => $1, :tags => ['new'], :received => $2
            end
          when /^\((\d+)\s*(\w+)\)$/
            CEML.incr_clock CEML.dur($1.to_i, $2)
            roll
          when /^#/
          else "Skipping line #{line}..."
          end
        end
      end
    end
  end

end
