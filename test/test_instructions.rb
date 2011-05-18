require 'ceml'

class TestInstructions < Test::Unit::TestCase
  def pi text
    CEML.parse(:instructions, text)
  end

  def ps text
    CEML.parse(:script, text)
  end

  def assert_bad text
    assert_raise(RuntimeError){ pi text }
  end

  def test_bad
    assert_bad "love your mother"
    assert_bad "tell jim re susan: i hate you"
    assert_bad "tell phil"
    assert_bad "ask susan re clothing"
    assert_bad "ask susan re clothing: "
    assert_bad "seed X with"
    assert_bad "seed X with foo as "
    assert_bad "pick X from"
  end

  def test_instructions
    pi "seed X with Y"
    x = pi "seed X with Y as Z"
    puts x.bytecode.inspect
    # pi "pick X from a, b, c or d"
    pi "pick foo bar:\n  lalalala\n  babababa"
    pi "replace finder unless yes"
    x = ps('tell joe: run to the kitchen')
    # p x
    assert_equal "run to the kitchen", x.simple_message
    # assert_equal ["favorite color?", "favorite soup?"], pi(
    #   "ask joe re color: favorite color?\nask joe re soup: favorite soup?"
    # ).i_asks([:joe]).map(&:text)
  end

end
