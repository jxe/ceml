require 'rubygems'
require 'test/unit'

SCRIPTS = {}
Dir["test/*.ceml"].each do |f|
  name = File.basename(f, '.ceml')
  SCRIPTS[name] = File.new(f).read
end

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

  def scriptfam scripts
    CEML.parse(:scripts, scripts).map(&:castable)
  end

  def ping s, candidate
    CEML::Processor.set_bundle(s.hash.to_s, s)
    CEML::Processor.ping(s.hash.to_s, candidate)
    CEML::Processor.run
  end

  def says id, str
    player = {:id => id.to_s, :received => str}
    player[:recognized] = :yes if str.downcase == 'y' || str.downcase == 'yes'
    player[:recognized] = :abort if str == 'abort'
    puts "SAYING(#{id}): #{str}"
    CEML::Processor.ping(nil, player)
    CEML::Processor.run
  end

  def silent id
    id = id.to_s
    p = CEML::Processor::JUST_SAID[id]
    assert !p || p.empty?
  end

  def told id, rx
    id = id.to_s
    assert CEML::Processor::JUST_SAID[id]
    assert p = CEML::Processor::JUST_SAID[id].shift
    assert_match rx, p[:msg] || p[:q]
  end
  alias_method :asked, :told

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
