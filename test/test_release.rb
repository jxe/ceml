require 'ceml'
require 'test/helper'

class TestRelease < Test::Unit::TestCase

  # def test_release_syntax
  #   s = CEML.parse(:script, "release all as booger")
  #   assert l=s.bytecode.find{ |line| line[1] == :release }
  #   assert_equal 'booger', l[2][:tag]
  #
  #   s = CEML.parse(:script, "release all as booger if yes")
  #   puts s.bytecode.inspect
  #   assert l=s.bytecode.find{ |line| line[1] == :release }
  #   assert_equal 'booger', l[2][:tag]
  #   assert_equal :if, l[2][:cond][0]
  #   assert_equal :yes, l[2][:cond][1]
  # end
  #
  # def test_release_and_catch
  #   s1 = "await 1 new signup\nrelease signup as confused"
  #   s2 = "await 1 confused booger\ntell booger: you're okay dude"
  #   f = scriptfam s1, s2
  #   play do
  #     ping f, :id => 'sam', :tags => ['new']
  #     told 'sam', /okay dude/
  #   end
  # end
  #
  # def test_conditional_release_and_catch
  #   s1 = "await 1 new signup\nask signup re coffee: want some?\nrelease signup as confused if yes"
  #   s2 = "await 1 confused booger\ntell booger: you're okay dude"
  #   f = scriptfam s1, s2
  #   play do
  #     ping f, :id => 'sam', :tags => ['new']
  #     asked 'sam', /want/
  #     says 'sam', 'y'
  #     told 'sam', /okay dude/
  #   end
  # end


SAM_IAN_SIGNUP_SCRIPTS = <<XXXX
await 1 new signup
ask signup re first_name:
 Thanks for signing up for Infatuated!
 What's your first name?
ask signup re code:
 Type in your Infatuated Match Card code now.
release signup as coded

await 1 coded alpha and 1 coded beta with matching code
tell alpha: You are alpha |her.first_name|, beta is |buddy.first_name|
tell beta: You are beta |her.first_name|, alpha is |buddy.first_name|
XXXX

  #
  # def test_couple
  #   f = scriptfam *CEML.parse(:scripts, SAM_IAN_SIGNUP_SCRIPTS)
  #   play do
  #     ping f, :id => 'Sara', :tags => ['new']
  #     ping f, :id => 'Jon',  :tags => ['new']
  #     asked 'Sara', /Thanks/
  #     says 'Sara', 'Sara'
  #
  #     asked 'Jon',  /Thanks/
  #     says 'Jon',  'Jon'
  #
  #     asked 'Sara', /Match Card/
  #     asked 'Jon',  /Match Card/
  #     says 'Sara', 'xyzzy'
  #     says 'Jon', 'xyZZy '
  #
  #     told 'Sara', /alpha Sara, beta is Jon/
  #     told 'Jon', /beta Jon, alpha is Sara/
  #   end
  # end
  #
end