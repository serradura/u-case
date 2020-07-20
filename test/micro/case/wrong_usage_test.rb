require 'test_helper'

class Micro::Case::WrongUsageTest < Minitest::Test
  class WrongSuccessResult < Micro::Case
    attributes :a, :b

    def call!
      Success result: a / b
    rescue ZeroDivisionError => exception
      Failure result: exception
    end
  end

  def test_the_wrong_usage_error_by_set_an_invalid_success_result
    assert_raises_with_message(
      Micro::Case::Error::InvalidSuccessResult,
      "Success(result: 2) must be a Hash or Symbol"
    ) { WrongSuccessResult.call(a: 4, b: 2) }
  end

  class WrongFailureResult < Micro::Case
    attributes :a, :b

    def call!
      Success result: { division: a / b }
    rescue ZeroDivisionError => exception
      Failure result: 0
    end
  end

  def test_the_wrong_usage_error_by_set_an_invalid_failure_result
    assert_raises_with_message(
      Micro::Case::Error::InvalidFailureResult,
      "Failure(result: 0) must be a Hash, Symbol or an Exception"
    ) { WrongFailureResult.call(a: 4, b: 0) }
  end
end
