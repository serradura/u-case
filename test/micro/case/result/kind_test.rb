require 'test_helper'

class Micro::Case::Result::KindTest < Minitest::Test
  def test_the_micro_case_result_kind_checker
    assert_raises_with_message(
      Kind::Error,
      'nil expected to be a kind of Micro::Case::Result'
    ) { Kind.of.Micro::Case::Result(nil) }

    assert_raises_with_message(
      Kind::Error,
      '{} expected to be a kind of Micro::Case::Result'
    ) { Kind.of.Micro::Case::Result({}) }

    # --

    result1 = Jobs::Build.call
    result2 = Micro::Case::Result.new

    assert_same(result1, Kind.of.Micro::Case::Result(result1))
    assert_same(result1, Kind.of.Micro::Case::Result(nil, or: result1))

    assert_raises_with_message(
      Kind::Error,
      '"default" expected to be a kind of Micro::Case::Result'
    ) { Kind.of.Micro::Case::Result(nil, or: 'default') }

    # to_proc

    assert_equal([result2, result1], [result2, result1].map(&Kind.of.Micro::Case::Result))

    assert_raises_with_message(
      Kind::Error,
      '{} expected to be a kind of Micro::Case::Result'
    ) { [{}, result1].select(&Kind.of.Micro::Case::Result) }

    # --

    assert(Kind.of.Micro::Case::Result?(result1))
    assert(Kind.of.Micro::Case::Result?(result1, result2))

    assert_equal([result1, result2], [{}, result1, nil, result2].select(&Kind.of.Micro::Case::Result?))

    # instance?

    assert(Kind.of.Micro::Case::Result.instance?(result1))
    assert(Kind.of.Micro::Case::Result.instance?(result1, result2))

    assert_equal([result1, result2], [{}, result1, nil, result2].select(&Kind.of.Micro::Case::Result.instance?))

    # or_nil

    assert_nil Kind.of.Micro::Case::Result.or_nil({})
    assert_same(result1, Kind.of.Micro::Case::Result.or_nil(result1))

    # -- Kind.of.Micro::Case::Result.as_optional

    valid_instances = [result1, result2]
    invalid_instances = [{}, nil, 1, '']

    invalid_instances.each do |invalid_instance|
      assert_instance_of(
        Kind::Optional::None,
        Kind.of.Micro::Case::Result.as_optional(invalid_instance)
      )
    end

    assert(invalid_instances.map(&Kind.of.Micro::Case::Result.as_optional).all?(&:none?))

    valid_instances.each do |valid_instance|
      assert_instance_of(
        Kind::Optional::Some,
        Kind.of.Micro::Case::Result.as_optional(valid_instance)
      )
    end

    assert(valid_instances.map(&Kind.of.Micro::Case::Result.as_optional).all?(&:some?))
  end
end
