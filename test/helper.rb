require 'rubygems'
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'ceml'

class Test::Unit::TestCase
  def play script = nil
    if String === script
      script = CEML.parse(:script, script)
    end
    if script
      @iid = gen_code
      puts "launching w. bytecode #{script.bytecode.inspect}"
      CEML::Processor.launch(@iid, script.bytecode)
      CEML::Processor.run
    end
    yield
    CEML::Processor::JUST_SAID.clear
  end

  def scriptfam *scripts
    scripts.map do |script|
      if String === script
        CEML.parse(:script, script).castable
      else
        script.castable
      end
    end
  end

  def ping s, candidate
    CEML::Processor.set_bundle(s.hash.to_s, s)
    CEML::Processor.audition(s.hash.to_s, candidate)
    CEML::Processor.run
  end

  def says id, str
    player = {:id => id.to_s, :received => str}
    player[:recognized] = :yes if str == 'y'
    player[:recognized] = :abort if str == 'abort'
    puts "SAYING(#{id}): #{str}"
    CEML::Processor.replied(nil, player)
    CEML::Processor.run
  end

  def asked id, rx
    id = id.to_s
    assert p = CEML::Processor::JUST_SAID[id]
    assert_equal :ask, p[:said]
    assert_match rx, p[:q]
    CEML::Processor::JUST_SAID.delete id
  end

  def silent id
    id = id.to_s
    assert !CEML::Processor::JUST_SAID[id]
  end

  def told id, rx
    id = id.to_s
    assert p = CEML::Processor::JUST_SAID[id]
    assert_match rx, p[:msg]
    CEML::Processor::JUST_SAID.delete id
  end

  def player id, role
    CEML::Player.new(id.to_s).clear_answers
    CEML::Processor.add_cast(@iid, { role => [{ :id => id.to_s }]})
    CEML::Processor.run
  end

  def roll
    CEML::Processor.run_latest
    CEML::Processor.run
  end
end
