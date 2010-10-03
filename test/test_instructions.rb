require 'tryst'

class TestInstructions < Test::Unit::TestCase
  def pi text
    Tryst.parse(:instructions, text)
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
  end

  def test_instructions
    assert_equal "run to the kitchen", pi('tell joe: run to the kitchen').tell([:joe]).text
    assert_equal ["favorite color?", "favorite soup?"], pi(
      "ask joe re color: favorite color?\nask joe re soup: favorite soup?"
    ).asks([:joe]).map(&:text)
  end

end
