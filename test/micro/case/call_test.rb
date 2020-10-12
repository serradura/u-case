require 'ostruct'
require 'test_helper'
require 'support/steps'

class Micro::Case::CallTest < Minitest::Test
  class Sum < Micro::Case
    attributes :a, :b

    def call!
      return Success(result: { number: a + b }) if Kind.of?(Numeric, a, b)

      Failure(:attributes_must_be_numbers)
    end
  end

  class Add3 < Micro::Case
    attribute :number

    def call!
      return Success(result: { number: number + 3 }) if number.is_a?(Numeric)

      Failure(:attribute_must_be_a_number)
    end
  end

  Add9 = Micro::Cases.flow([Add3, Add3, Add3])

  class SumAndAdd9 < Micro::Case
    flow([Sum, Add9])
  end

  class SumAndAdd18 < Micro::Case
    attributes :a, :b

    def call!
      call(Sum)
        .then(Add9)
        .then(Add9)
    end
  end

  class SumWithOneDefaultAndAdd6 < Micro::Case
    attributes :a, :b

    def call!
      call(Sum, b: (b || 2))
        .then(Add3)
        .then(Add3)
    end
  end

  class SumWithoutAttributesAndAdd3 < Micro::Case
    def call!
      call(Sum)
        .then(Add3)
    end
  end

  class SumWithoutAttributesAndOneDefaultAndAdd3 < Micro::Case
    def call!
      call(Sum, b: 3)
        .then(Add3)
    end
  end

  def test_the_calling_of_use_cases
    [1, nil, []].each do |arg|
      assert_raises(Kind::Error) { Sum.call(arg) }
      assert_raises(Kind::Error) { Add3.call(arg) }
      assert_raises(Kind::Error) { Add9.call(arg) }

      assert_raises(Kind::Error) { SumAndAdd9.call(arg) }

      assert_raises(Kind::Error) { SumAndAdd18.call(arg) }
      assert_raises(Kind::Error) { SumWithOneDefaultAndAdd6.call(arg) }
      assert_raises(Kind::Error) { SumWithoutAttributesAndAdd3.call(arg) }
      assert_raises(Kind::Error) { SumWithoutAttributesAndOneDefaultAndAdd3.call(arg) }

      assert_raises(Kind::Error) { Add9.call(arg).then(Add9) }
    end

    # --

    assert_predicate(Sum.call(), :failure?)
    assert_predicate(Add3.call(), :failure?)
    assert_predicate(Add9.call(), :failure?)

    assert_predicate(SumAndAdd9.call(), :failure?)

    assert_predicate(SumAndAdd18.call(), :failure?)
    assert_predicate(SumWithOneDefaultAndAdd6.call(), :failure?)
    assert_predicate(SumWithoutAttributesAndAdd3.call(), :failure?)
    assert_predicate(SumWithoutAttributesAndOneDefaultAndAdd3.call(), :failure?)

    assert_predicate(Add9.call().then(Add9), :failure?)

    # --

    assert_equal(2, Sum.call(a: 1, b: 1)[:number])
    assert_equal(4, Add3.call(number: 1)[:number])
    assert_equal(10, Add9.call(number: 1)[:number])

    assert_equal(18, SumAndAdd9.call(a: 4, b: 5)[:number])

    assert_equal(20, SumAndAdd18.call(a: 1, b: 1)[:number])
    assert_equal(10, SumWithOneDefaultAndAdd6.call(a: 2)[:number])
    assert_equal(5, SumWithoutAttributesAndAdd3.call(a: 1, b: 1)[:number])
    assert_equal(7, SumWithoutAttributesAndOneDefaultAndAdd3.call(a: 1)[:number])

    assert_equal(20, Add9.call(number: 2).then(Add9)[:number])
  end
end
