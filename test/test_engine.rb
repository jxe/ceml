require 'fete'

class TestEngine < Test::Unit::TestCase

  SCRIPT = <<END_OF_SCRIPT
"Overwhelm a specific person with compliments"
gather 5-20 players within 4 blocks
ask organizer re target: Describe their appearance and location
tell players: Look for |target| and compliment them briefly, then move on.
END_OF_SCRIPT

  def test_engine
    e = Fete::Engine.new(SCRIPT)
    e.add('joe', :agent)
    e.run

    puts e.elements['joe'][:said]
    puts e.elements['joe'][:q]
  end

end
