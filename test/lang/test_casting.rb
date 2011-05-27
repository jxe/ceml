require 'test/unit'
require 'ceml'

class TestCasting < Test::Unit::TestCase
  def pcs text
    CEML.parse(:casting_statement, text)
  end

  def assert_bad text
    assert_raise(RuntimeError){ pcs text }
  end

  def test_bad
    assert_bad "gather a-b runners"
    assert_bad "gather 40a runners"
    assert_bad "gather 3- runners"
    assert_bad "gather -4 runners"
    assert_bad "grab 4 runners"
    assert_bad "gather 4 *runners"
    assert_bad "gather 4 run*ners"
    assert_bad "gather 4 runners*"
    assert_bad "() gather a-b runners"
  end

  def test_range
    cs = pcs "gather 3-4 runners"
    assert cs.type == :gather
    assert cs.roles.names.include? :runners
    assert cs[:runners].min == 3
    assert cs[:runners].max == 4
    assert cs.max == 4

    cs = pcs "gather 3+ runners"
    assert cs.type == :gather
    assert cs.roles.names.include? :runners
    assert cs[:runners].min == 3
    assert cs[:runners].max > 4
    assert cs.min == 3
    assert cs.max > 4

    cs = pcs "gather 3 runners"
    assert cs.type == :gather
    assert cs.roles.names.include? :runners
    assert cs[:runners].min == 3
    assert cs[:runners].max == 3
    assert cs.min == 3
    assert cs.max == 3

    cs = pcs "gather runners"
    assert cs.type == :gather
    assert cs.roles.names.include? :runners
    assert cs[:runners].min == 2
    assert cs[:runners].max > 10
    assert cs.min == 2
    assert cs.max > 10

    cs = pcs "gather 1-2 runners and 1 announcer"
    assert cs.type == :gather
    assert cs.roles.names.include? :runners
    assert cs.roles.names.include? :announcer
    assert cs[:runners].min == 1
    assert cs[:runners].max == 2
    assert cs.min == 2
    assert cs.max == 3

    cs = pcs "nab 1-2 runners within 4 mi"
    assert cs.type == :nab
    assert cs.nab?
    assert cs[:runners].min == 1
    assert cs[:runners].max == 2
  end

  def test_radius
    assert_equal 600, pcs("gather 3 runners and 5 hot_babes within 3 blocks").radius
    assert !pcs("gather 3 runners and 5 hot_babes").radius
  end

  def test_stanza
    assert_equal 'woot', pcs("(woot)\nawait 3 runners and 5 hot_babes within 3 blocks").stanza_name
  end

end
