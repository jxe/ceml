require 'rubygems'
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'ceml'

class Test::Unit::TestCase
  def play script = nil
    @e = CEML::Incident.new(script) if script
    yield
    CEML::Delegate::PLAYERS.clear
  end

  def player id, *roles
    @e.run do |script|
      script.add id, *roles
    end
  end

  def asked id, rx
    assert g = CEML::Delegate::PLAYERS.values.find{ |game| game[id] }
    p = g[id]
    assert_equal :ask, p[:said]
    assert_match rx, p[:q]
    p.delete :said
  end

  def silent id
    if g = CEML::Delegate::PLAYERS.values.find{ |game| game[id] }
      p = g[id]
      assert !p[:msg]
    end
  end

  def told id, rx
    assert g = CEML::Delegate::PLAYERS.values.find{ |game| game[id] }
    p = g[id]
    assert_match rx, p[:msg]
    p.delete :said
  end

  def says id, str
    @e.run do |incident|
      incident.players[id][:received] = str
    end

    CEML.delegate.with_players(@e.id) do |players|
      players[id][:received] = nil
    end
  end
end
