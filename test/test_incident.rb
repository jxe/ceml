require 'ceml'
require 'test/helper'

COMPLIMENT_SCRIPT = <<XXX
"Overwhelm a specific person with compliments"
gather 5-20 players within 4 blocks
ask organizer re target: Describe their appearance and location
tell agents: Look for |somebody.target| and compliment them briefly, then move on.
XXX

JANE_SCRIPT = <<XXX

await 1 new signup
register signup first_name
ask signup re shoeless:
  Hello |his.first_name|. You are Level Zero. Lowly level zero.
  To advance to Level 1, please remove a shoe. Keep it off,
  and text back "shoeless".
tell signup:
  O ho! Well done |his.first_name|. Now the other players
  know you're in the game, too. But you're still a sad Level 1.
ask signup re game:
  To advance to Level 2, answer this question. What was your
  favorite game when you were 10 years old? Tell me now.
tell signup:
  Ah yes. |his.game| WAS an amazing game. You should try to play
  it again--sometime this week, perhaps?
  In the meantime you are but a mere Level 2. Let's see if we can do
  something about that. (You still have your shoe off, right?)
ask signup re friend:
  While you're texting... Pick someone in your address book you
  haven't talked to in a while. Send them an SMS
  just to say hello. Then tell me their first name.
tell signup:
  That was awfully nice of you to message |his.friend|
  Welcome to the amazing Level 3. You'll like it here. Stay awhile.
tell signup:
  Just kidding. Level 4 is way better than this. To get to
  Level 4, wait for an appropriate moment in Jane's talk
  and shout an encouraging "Amen!" Yes. Out loud.
ask signup re amen:
  If you're not the spiritual type, a forceful "YEAH!" will do.
  When you've accomplished your mission, text me "amen".
tell signup:
  Wow. I didn't think you had it in you. No one has ever gotten to
  Level 4 before. This is VERY exciting.
tell signup:
  If you get to Level 5, I'll give you a secret password. Tell it to
  Jane, and you'll get some very fancy loot.
ask signup re ovation:
  All you have to do is wait until the end of Jane's talk--and try to
  spark a standing ovation. Good luck! Text ovation afterward for your
  password.
tell signup:
  You did it! You are Level 5. You are AMAZING. The conquering hero of
  the entire audience! Now I can give you your password.
tell signup:
  Ask Jane to sign a copy of her book to Mr. Gamey McGameful. Of course,
  this will only work if she saw you standing in that ovation. You were
  standing, right?
XXX

class TestIncident < Test::Unit::TestCase

  def test_jane
    s = CEML.parse(:script, JANE_SCRIPT)
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
    s = CEML.parse(:script, "await 1 new signup\ntell signup: thanks")
    play do
      ping s, :id => 'fred', :tags => ['new']
      told 'fred', /thanks/
    end
  end

  def test_signup_2
    s = CEML.parse(:script, "await 2 new signups\ntell signups: thanks")
    play do
      ping s, :id => 'fred', :tags => ['new']
      silent 'fred'
      ping s, :id => 'wilma', :tags => ['old']
      silent 'fred'
      ping s, :id => 'betty', :tags => ['new']
      told 'fred', /thanks/
    end
  end

  def test_await
    s = CEML.parse(:script, "await a,b,c\ntell a: foo\ntell b: bar\ntell c: baz")
    play do
      ping s, :id => 'fred'
      silent 'fred'
      ping s, :id => 'wilma'
      silent 'fred'
      silent 'wilma'
      ping s, :id => 'betty'
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

ASKCHAIN_SCRIPT = <<XXX
"Meet your neighbor"
gather 2 players within 1 block
ask players re color: what's your favorite color?
ask players re observation: find someone near you with the color |somebody.color|. what are they wearing?
ask players re rightmatch: are you wearing |somebody.observation|?
ask players re task: take your new partner and see if you can find something beautiful in the park.
XXX


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
