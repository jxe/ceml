require 'ceml'

class TestInstructions < Test::Unit::TestCase

  SCRIPTS = <<END_OF_SCRIPTS
"Help moving |an object|" // okay?
gather 2-6 movers within 8 blocks

"Cleaning up |a public place|"
gather 3-10 cleaners within 2 miles

// the following are dedicated to my mom

"Overwhelm a specific person with compliments"
gather 5-20 players within 4 blocks
ask organizer re target: Describe their appearance and location
tell players: Look for |target| and compliment them briefly, then move on.
END_OF_SCRIPTS

  def ps text
    CEML.parse(:scripts, text)
  end

  def test_scripts
    s = ps SCRIPTS
    assert s.size == 3
    s0 = s[0]
    assert_equal "Help moving |an object|", s0.title
    assert s0.allowed_roles.include? :movers
    assert s0.radius == 1600
    assert s0.dramatis_personae.min == 2
    assert s0.dramatis_personae.max == 6
  end

  def test_ceml_title
    s = CEML.parse(:script, '"hello there"')
    assert_equal "hello there", s.title

    s = CEML.parse(:script, %q{"say: \"whoa the'a paps\""})
    assert_equal %Q{say: "whoa the'a paps"}, s.title
  end

  def test_ceml_tell
    cs = CEML.parse(:script, "tell agents: run and jump")
    assert cs.roles.include? :agents
    assert_equal "run and jump", cs.instructions.tell([:agents]).text
    assert cs.concludes_immediately?
    assert !cs.title
  end

  def test_ceml_questions
    s = CEML.parse(:script, "ask agents: wassup party people?")
    assert_equal "wassup party people?", s.instructions.asks([:agents]).first.text
    assert !s.concludes_immediately?
  end

end
