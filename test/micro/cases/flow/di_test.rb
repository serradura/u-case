require 'test_helper'

class Micro::Cases::Flow::DITest < Minitest::Test
  class Add2 < Micro::Case
    attribute :number

    def call!
      number.is_a?(Numeric) ? Success(result: { number: number + 2 }) : Failure()
    end
  end

  class Add3 < Micro::Case
    attribute :number

    def call!
      number.is_a?(Numeric) ? Success(result: { number: number + 3 }) : Failure()
    end
  end

  class Sum < Micro::Case
    attributes :number, :adder

    def call!
      call(adder)
    end
  end

  Add10 = Micro::Cases.flow([
    Add2,
    [Sum, adder: Add3],
    [Sum, adder: Add2],
    Add3
  ])

  Add20 = Micro::Cases.flow([
    Add10,
    Add10
  ])

  def test_dependency_injection_using_a_collection_of_use_cases
    result = Add10.call(number: 1)

    assert_predicate(result, :success?)

    assert_equal(11, result[:number])

    # --

    result = Add20.call(number: 1)

    assert_predicate(result, :success?)

    assert_equal(21, result[:number])
  end
end
