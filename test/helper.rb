require 'rubygems'
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'ceml'

class Test::Unit::TestCase
  DRIVER = CEML::Driver.new

  def play script = nil
    @iid = script && DRIVER.start(nil, script)
    yield
    CEML::Driver::JUST_SAID.clear
    CEML::Driver::PLAYERS.clear
    CEML::Driver::INCIDENTS.clear
  end

  def ping s, candidate
    DRIVER.ping s, candidate
  end

  def says id, str
    iid = CEML::Driver::INCIDENTS.keys.find do |iid|
      CEML::Driver::PLAYERS[iid].find{ |p| p[:id] == id }
    end
    DRIVER.post iid, :id => id, :received => str
  end

  def player id, *roles
    DRIVER.post @iid, :id => id, :roles => roles
  end

  def roll
    DRIVER.post @iid
  end

  def asked id, rx
    assert p = CEML::Driver::JUST_SAID[id]
    assert_equal :ask, p[:said]
    assert_match rx, p[:q]
    CEML::Driver::JUST_SAID.delete id
  end

  def silent id
    assert !CEML::Driver::JUST_SAID[id]
  end

  def told id, rx
    assert p = CEML::Driver::JUST_SAID[id]
    assert_match rx, p[:msg]
    CEML::Driver::JUST_SAID.delete id
  end
end
