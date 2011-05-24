require 'ceml'
require 'test/helper'

class TestIncident < Test::Unit::TestCase

  def setup
    CEML::Queue.new.calls.clear
  end

  def test_sync
    s = scriptfam SCRIPTS['sync']
    play do
      ping s, :id => 'alpha', :tags => ['new']
      ping s, :id => 'beta', :tags => ['new']
      asked 'alpha', /olor/
      asked 'beta', /olor/
      says 'alpha', "red"
      silent 'alpha'
      says 'beta', "blue"
      told 'beta', /Hi/
      told 'alpha', /Goodbye/
    end
  end

  def test_jane
    s = scriptfam SCRIPTS['jane']
    play do
      ping s, :id => 'fred', :tags => ['new'], :received => 'freddy'
      asked 'fred', /Hello freddy. You are Level Zero./
      says 'fred', "shoeless"
      asked 'fred', /favorite game/
      says 'fred', "monopoly"
      asked 'fred', /Pick someone in your address/
      says 'fred', 'jim'
      asked 'fred', /forceful/
      says 'fred', 'okay'
      asked 'fred', /standing ovation/
      says 'fred', 'did it'
      told 'fred', /Gamey/
    end
  end

  def test_delay
    s = CEML.parse(:script, "tell agents: hello\n5s later tell agents: goodbye")
    play s do
      player :bill, :agent
      told :bill, /hello/
      silent :bill
      CEML.incr_clock 5
      roll
      told :bill, /goodbye/
    end
  end

  def test_signup_1
    s = scriptfam "await 1 new signup\ntell signup: thanks"
    play do
      ping s, :id => 'fred', :tags => ['new']
      told 'fred', /thanks/
    end
  end

  def test_signup_2
    s = scriptfam "await 2 new signups\ntell signups: thanks"
    play do
      ping s, :id => 'fred', :tags => ['new']
      # silent 'fred'
      # ping s, :id => 'wilma', :tags => ['old']
      # silent 'fred'
      # ping s, :id => 'betty', :tags => ['new']
      told 'fred', /thanks/
    end
  end


  # def test_inside_timewindow
  #   s = scriptfam "await 2 new signups over 10s\ntell signups: thanks"
  #   play do
  #     ping s, :id => 'fred', :tags => ['new']
  #     silent 'fred'
  #     CEML.incr_clock 5
  #     ping s, :id => 'betty', :tags => ['new']
  #     told 'fred', /thanks/
  #   end
  # end
  #
  # def test_outside_timewindow
  #   s = scriptfam "await 2 new signups over 10s\ntell signups: thanks"
  #   play do
  #     ping s, :id => 'fred', :tags => ['new']
  #     silent 'fred'
  #     CEML.incr_clock 15
  #     ping s, :id => 'betty', :tags => ['new']
  #     silent 'fred'
  #   end
  # end

  def test_interpolation
    s = "\"Soccer in the park\"\ngather 2 players within 1mi\nask players re color: which color?\ntell players: its |someone.color|\n"
    s = CEML.parse(:script, s)
    play s do
      player :bill, :players
      player :fred, :players
      asked :bill, /color\?/i
      asked :fred, /color\?/i
      says :bill, 'red'
      says :fred, 'blue'
      told :fred,  /its red/i
      told :bill,  /its blue/i
    end
  end

  def test_abort
    s = "\"Soccer in the park\"\ngather 2 players within 1mi\nask players re color: which color?\ntell players: its |someone.color|\n"
    s = CEML.parse(:script, s)
    play s do
      player :bill, :players
      player :fred, :players
      asked :bill, /color\?/i
      asked :fred, /color\?/i
      says :bill, 'abort'
      told :bill,  /aborted/i
    end
  end

  def test_await
    s = scriptfam "await new a, new b, new c\ntell a: foo\ntell b: bar\ntell c: baz"
    play do
      ping s, :id => 'fred', :tags => ['new']
      silent 'fred'
      ping s, :id => 'wilma', :tags => ['new']
      silent 'fred'
      silent 'wilma'
      ping s, :id => 'betty', :tags => ['new']
      told 'fred', /foo/
      told 'betty', /baz/
    end
  end

  def test_incident
    play SCRIPTS['compliment'] do
      player :joe, :organizer
      player :bill, :agent

      asked :joe, /^Describe/
      says :joe, 'red people'

      told :bill, /^Look for red people/
    end
  end

  def test_askchain
    play SCRIPTS['askchain'] do
      player :joey, :players
      player :billy, :players

      asked :joey,  /favorite color/
      asked :billy, /favorite color/
      says :joey, "red"
      says :billy, "green"
      asked :joey, /with the color green/
      asked :billy, /with the color red/
    end
  end

end
