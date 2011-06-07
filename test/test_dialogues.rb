require 'ceml'
require 'test/helper'
require 'set'

class TestCemlTests < Test::Unit::TestCase

  def setup
    CEML::Queue.new.calls.clear
  end

  def run_cemltest f
    name = File.basename(f, '.ceml')
    err, log = CEML.test(File.new(f).read)
    if !err
      puts "PASS cemltest #{name}.  logged #{log.split("\n").size} lines"
    elsif RuntimeError === err
      puts log
      raise "ERROR with cemltest #{name}: #{err.message}!"
    else
      raise err
    end
  end

  def test_cemltests
    Dir["test/dialogues/*.ceml"].each{ |f| run_cemltest(f) }
  end
end
