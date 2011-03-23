require 'test/unit'
require 'ceml'

class TestCastable < Test::Unit::TestCase

  def test_castable
    s = CEML.parse(:script, "await 1 alpha and 1 beta\ntell both: hi")
    bid = s.castable.cast_from [{ :id => 'jim' }, { :id => 'bob' }]
    assert bid.guys.size == 2
    assert bid.cast['alpha'].size == 1
    assert bid.cast['beta'].size == 1
  end

end
