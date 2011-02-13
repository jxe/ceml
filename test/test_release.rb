require 'ceml'
require 'test/helper'

class TestRelease < Test::Unit::TestCase

  def test_release_syntax
    s = CEML.parse(:script, "release all as booger")
    assert l=s.bytecode.find{ |line| line[1] == :release }
    assert_equal 'booger', l[2][:tag]

    s = CEML.parse(:script, "release all as booger if yes")
    puts s.bytecode.inspect
    assert l=s.bytecode.find{ |line| line[1] == :release }
    assert_equal 'booger', l[2][:tag]
    assert_equal :if, l[2][:cond][0]
    assert_equal :yes, l[2][:cond][1]
  end

  def test_release_and_catch
    s1 = "await 1 new signup\nrelease signup as confused"
    s2 = "await 1 confused booger\ntell booger: you're okay dude"
    f = scriptfam s1, s2
    play do
      ping f, :id => 'sam', :tags => ['new']
      told 'sam', /okay dude/
    end
  end

  def test_conditional_release_and_catch
    s1 = "await 1 new signup\nask signup re coffee: want some?\nrelease signup as confused if yes"
    s2 = "await 1 confused booger\ntell booger: you're okay dude"
    f = scriptfam s1, s2
    play do
      ping f, :id => 'sam', :tags => ['new']
      asked 'sam', /want/
      says 'sam', 'y'
      told 'sam', /okay dude/
    end
  end


SAM_IAN_SIGNUP_SCRIPTS = <<XXXX
await 1 new signup
ask signup re first_name:
 Thanks for signing up for Infatuated!
 What's your first name?
ask signup re couple:
 Do you have an Infatuated Match Card you want to use?
 (These are available at the Infatuated table on the first floor.)
release signup as stage=couple if yes
ask signup re tags:
 Who are you and who are you looking for tonight? (text back one: w4w, w4m, m4m, or m4w)

await stage=couple player
ask player re code:
 Type in your Infatuated Match Card code now.
release player as stage=coded

await 1 stage=coded alpha and 1 stage=coded beta with matching code
release alpha as alpha
release beta as beta

await 1 w4w alpha and 1 w4w beta
release alpha as alpha
release beta as beta

await 1 w4m alpha and 1 m4w beta
release alpha as alpha
release beta as beta

await 1 m4m alpha and 1 m4m beta
release alpha as alpha
release beta as beta

await 1 m4w alpha and 1 w4m beta
release alpha as alpha
release beta as beta

await 1 alpha alpha, 1 beta beta over 5 minutes
tell both: Your date has started, |her.first_name|, |buddy.first_name|
XXXX


  def test_couple
    f = scriptfam *CEML.parse(:scripts, SAM_IAN_SIGNUP_SCRIPTS)
    play do
      ping f, :id => 'Sara', :tags => ['new']
      ping f, :id => 'Jon',  :tags => ['new']
      asked 'Sara', /Thanks/
      says 'Sara', 'Sara'
      asked 'Sara', /Match Card/
      says 'Sara', 'y'
      asked 'Jon',  /Thanks/
      says 'Jon',  'Jon'
      asked 'Jon',  /Match Card/
      says 'Jon',  'y'
      asked 'Sara', /code now/
      says 'Sara', 'xyzzy'
      asked 'Jon', /code now/
      says 'Jon', 'xyZZy '
      told 'Sara', /started, Sara, Jon/
      told 'Jon', /started, Jon, Sara/
    end
  end

end