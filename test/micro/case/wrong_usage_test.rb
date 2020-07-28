require 'test_helper'

class Micro::Case::WrongUsageTest < Minitest::Test
  class WrongSuccessResult < Micro::Case
    attributes :a, :b

    def call!
      if b < 0
        Success :divided_by_negative, result: a / b
      else
        Success result: a / b
      end
    rescue ZeroDivisionError => exception
      Failure result: exception
    end
  end

  def test_the_wrong_usage_error_by_set_an_invalid_success_result
    err1 = assert_raises(
      Micro::Case::Error::InvalidResult,
    ) { WrongSuccessResult.call(a: 4, b: 2) }

    assert_equal(
      "The result returned from Micro::Case::WrongUsageTest::WrongSuccessResult#call! must be a Hash.\n" \
      "\n" \
      "Example:\n" \
      "  Success(result: { key: 'value' })",
    err1.message)

    # ---

    err2 = assert_raises(
      Micro::Case::Error::InvalidResult,
    ) { WrongSuccessResult.call(a: 4, b: -2) }

    assert_equal(
      "The result returned from Micro::Case::WrongUsageTest::WrongSuccessResult#call! must be a Hash.\n" \
      "\n" \
      "Example:\n" \
      "  Success(:divided_by_negative, result: { key: 'value' })",
    err2.message)
  end

  class WrongFailureResult < Micro::Case
    attributes :a, :b

    def call!
      if b < 0
        Failure :divided_by_negative, result: a / b
      else
        Success result: { division: a / b }
      end
    rescue ZeroDivisionError => exception
      Failure result: 0
    end
  end

  def test_the_wrong_usage_error_by_set_an_invalid_failure_result
    err1 = assert_raises(
      Micro::Case::Error::InvalidResult,
    ) { WrongFailureResult.call(a: 4, b: 0) }

    assert_equal(
      "The result returned from Micro::Case::WrongUsageTest::WrongFailureResult#call! must be a Hash.\n" \
      "\n" \
      "Example:\n" \
      "  Failure(result: { key: 'value' })",
      err1.message
    )

    # ---

    err2 = assert_raises(
      Micro::Case::Error::InvalidResult,
    ) { WrongFailureResult.call(a: 4, b: -2) }

    assert_equal(
      "The result returned from Micro::Case::WrongUsageTest::WrongFailureResult#call! must be a Hash.\n" \
      "\n" \
      "Example:\n" \
      "  Failure(:divided_by_negative, result: { key: 'value' })",
      err2.message
    )
  end
end
