require 'rubygems'
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'ceml'

class Test::Unit::TestCase
  def play script
    @e = CEML::Incident.new(script)
  end

  def player id, *roles
    @e.add id, *roles
    @e.run
  end

  def asked id, rx
    p = @e.players[id]
    assert_equal :ask, p[:said]
    assert_match rx, p[:q]
    p.delete :said
  end

  def told id, rx
    p = @e.players[id]
    assert_match rx, p[:msg]
    p.delete :said
  end

  def says id, str
    @e.players[id][:received] = str
    @e.run
    @e.players[id][:received] = nil
  end
end
