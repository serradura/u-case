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

  class SumABC < Micro::Case
    attributes :c, default: -> value { value.to_i unless value.nil? }

    def call!
      call(Sum)
        .then(apply(:add_c))
    end

    private

      def add_c(number:, **)
        return Failure() unless c.is_a?(Numeric)

        Success result: { number: number + c }
      end
  end

  class SumABC2 < Micro::Case
    attributes :c

    def call!
      call(Sum)
        .then(apply(:add_c), c: c || 2)
    end

    private

      def add_c(number:, c:, **)
        return Failure() unless c.is_a?(Numeric)

        Success result: { number: number + c }
      end
  end

  class SumAB_and_C < Micro::Case
    attributes :a, :b

    def call!
      call(SumABC)
    end
  end

  class SumABCAndAdd3 < Micro::Case
    def call!
      call(SumABC)
        .then(Add3)
    end
  end

  def test_the_calling_of_use_cases_without_blocks
    [1, nil, []].each do |arg|
      assert_raises(Kind::Error) { Sum.call(arg) }
      assert_raises(Kind::Error) { Add3.call(arg) }
      assert_raises(Kind::Error) { Add9.call(arg) }

      assert_raises(Kind::Error) { SumAndAdd9.call(arg) }

      assert_raises(Kind::Error) { SumAndAdd18.call(arg) }
      assert_raises(Kind::Error) { SumWithOneDefaultAndAdd6.call(arg) }
      assert_raises(Kind::Error) { SumWithoutAttributesAndAdd3.call(arg) }
      assert_raises(Kind::Error) { SumWithoutAttributesAndOneDefaultAndAdd3.call(arg) }

      assert_raises(Kind::Error) { SumABC.call(arg) }
      assert_raises(Kind::Error) { SumABC2.call(arg) }
      assert_raises(Kind::Error) { SumAB_and_C.call(arg) }
      assert_raises(Kind::Error) { SumABCAndAdd3.call(arg) }

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

    assert_predicate(SumABC.call(), :failure?)
    assert_predicate(SumABC2.call(), :failure?)
    assert_predicate(SumAB_and_C.call(), :failure?)
    assert_predicate(SumABCAndAdd3.call(), :failure?)

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

    assert_equal(4, SumABC.call(a: 1, b: 1, c: 2)[:number])
    assert_equal(6, SumABC2.call(a: 2, b: 2)[:number])
    assert_equal(5, SumAB_and_C.call(a: 2, b: 2, c: 1)[:number])
    assert_equal(12, SumABCAndAdd3.call(a: 3, b: 3, c: '3')[:number])

    assert_equal(20, Add9.call(number: 2).then(Add9)[:number])
  end

  def test_the_calling_of_use_cases_with_block
    [
      Sum,
      Add3,
      Add9,
      SumAndAdd9,
      SumAndAdd18,
      SumWithOneDefaultAndAdd6,
      SumWithoutAttributesAndAdd3,
      SumWithoutAttributesAndOneDefaultAndAdd3,
      SumABC,
      SumABC2,
      SumAB_and_C,
      SumABCAndAdd3
    ].each do |use_case|
      [1, nil, []].each do |arg|
        assert_raises(Kind::Error) { use_case.call(arg) { |_| } }
      end

      # --

      count_failure = 0

      output1 = use_case.call() do |on|
        on.failure { count_failure +=1 }
      end

      assert_equal(1, output1)
      assert_equal(1, count_failure)

      # --

      count_unknown = 0

      output2 = use_case.call() do |on|
        on.success { raise }
        on.failure(:foo) { raise }
        on.failure(:bar) { raise }
        on.unknown { count_unknown +=1 }
      end

      assert_equal(1, output2)
      assert_equal(1, count_unknown)
    end

    # --

    [
      [Sum, { a: 1, b: 1 }, 2],
      [Add3, { number: 1 }, 4],
      [Add9, { number: 1 }, 10],
      [SumAndAdd9, { a: 1, b: 1 }, 11],
      [SumAndAdd18, { a: 1, b: 1 }, 20],
      [SumWithOneDefaultAndAdd6, { a: 2 }, 10],
      [SumWithoutAttributesAndAdd3, { a: 1, b: 1 }, 5],
      [SumWithoutAttributesAndOneDefaultAndAdd3, { a: 1 }, 7],
      [SumABC, { a: 1, b: 1, c: 2 }, 4],
      [SumABC2, { a: 2, b: 2 }, 6],
      [SumAB_and_C, { a: 2, b: 2, c: 1 }, 5],
      [SumABCAndAdd3, { a: 3, b: 3, c: '3' }, 12]
    ].each do |use_case, input, expected_number|
      count_success = 0

      output = use_case.call(input) do |on|
        on.success do |result|
          count_success +=1
          result[:number]
        end
        on.success(:ok) { |_| count_success +=1 }
        on.success(:foo) { raise }
      end

      assert_equal(1, count_success)
      assert_equal(expected_number, output)
    end
  end
end
