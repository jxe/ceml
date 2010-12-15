require 'ceml'
require 'test/helper'

class TestIncident < Test::Unit::TestCase

  def test_incident
    play COMPLIMENT_SCRIPT
    player :joe, :organizer, :agent
    player :bill, :agent

    asked :joe, /^Describe/
    says :joe, 'red people'

    told :bill, /^Look for red people/
  end

  def test_askchain
    play ASKCHAIN_SCRIPT
    player :joe, :players, :agent
    player :bill, :players, :agent

    asked :joe,  /favorite color/
    asked :bill, /favorite color/
    says :joe, "red"
    says :bill, "green"
    asked :joe, /with the color green/
    asked :bill, /with the color red/
  end

end
