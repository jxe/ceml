require 'test/unit'
require 'ceml'

class TestCastable < Test::Unit::TestCase

  def test_castable
    s = CEML.parse(:script, "await 1 alpha and 1 beta\ntell both: hi")
    assert cast = s.castable.cast_from([{ :id => 'jim' }, { :id => 'bob' }])
    assert cast.folks.size == 2
    assert cast['alpha'].size == 1
    assert cast['beta'].size == 1
  end

  # next, create a waiting room and add jim and bob and verify that an incident is started

  # add jim and bob one at a time, and verify that an incident is started

  # add two people that don't satisfy the criteria, then a third who matches

end
