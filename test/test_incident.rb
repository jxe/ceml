require 'ceml'
require 'test/helper'

COMPLIMENT_SCRIPT = <<XXX
"Overwhelm a specific person with compliments"
gather 5-20 players within 4 blocks
ask organizer re target: Describe their appearance and location
tell agents: Look for |otherguy.target| and compliment them briefly, then move on.
XXX

ASKCHAIN_SCRIPT = <<XXX
"Meet your neighbor"
gather 2 players within 1 block
ask players re color: what's your favorite color?
ask players re observation: find someone near you with the color |otherguy.color|. what are they wearing?
ask players re rightmatch: are you wearing |otherguy.observation|?
ask players re task: take your new partner and see if you can find something beautiful in the park.
XXX


class TestIncident < Test::Unit::TestCase

  def test_signup_1
    s = CEML.parse(:script, "await 1 new signup\ntell signup: thanks")
    play do
      s.post CEML::Candidate.new('fred', ['new'], {})
      told 'fred', /thanks/
    end
  end

  def test_signup_2
    s = CEML.parse(:script, "await 2 new signups\ntell signups: thanks")
    play do
      s.post CEML::Candidate.new('fred', ['new'], {})
      silent 'fred'
      s.post CEML::Candidate.new('wilma', ['old'], {})
      silent 'fred'
      s.post CEML::Candidate.new('betty', ['new'], {})
      told 'fred', /thanks/
    end
  end

  def test_await
    s = CEML.parse(:script, "await a,b,c\ntell a: foo\ntell b: bar\ntell c: baz")
    play do
      s.post CEML::Candidate.new('fred', [], {})
      silent 'fred'
      s.post CEML::Candidate.new('wilma', [], {})
      silent 'fred'
      silent 'wilma'
      s.post CEML::Candidate.new('betty', [], {})
      told 'fred', /foo/
      told 'betty', /baz/
    end
  end

  def test_incident
    play COMPLIMENT_SCRIPT do
      player :joe, :organizer, :agent
      player :bill, :agent

      asked :joe, /^Describe/
      says :joe, 'red people'

      told :bill, /^Look for red people/
    end
  end

  def test_askchain
    play ASKCHAIN_SCRIPT do
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

end
