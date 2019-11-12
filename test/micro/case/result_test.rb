require 'test_helper'

class Micro::Case::ResultTest < Minitest::Test
  def build_use_case
    Micro::Case.new({})
  end

  def test_success_result
    result = Micro::Case::Result.new
    result.__set__(true, 1, :ok, nil)

    assert_predicate(result, :success?)
    assert_equal(1, result.value)

    assert_raises_with_message(
      Micro::Case::Error::InvalidAccessToTheUseCaseObject,
      'only a failure result can access its use case object'
    ) { result.use_case }

    # ---

    assert_equal(
      result,
      result
        .on_failure { raise }
        .on_success { assert(true) }
        .on_success { |value| assert_equal(1, value) }
    )

    # ---

    assert_instance_of(Micro::Case::Result, result)
  end

  def test_failure_result
    use_case = build_use_case

    result = Micro::Case::Result.new
    result.__set__(false, 0, :error, use_case)

    refute_result_success(result)
    assert_result_failure(result)

    assert_equal(0, result.value)
    assert_same(use_case, result.use_case)

    # ---

    assert_equal(
      result,
      result
        .on_failure { assert(true) }
        .on_failure { |value| assert_equal(0, value) }
        .on_failure { |_value, serv| assert_same(serv, use_case) }
        .on_success { raise }
    )

    # ---

    assert_instance_of(Micro::Case::Result, result)
  end

  def test_value
    success_number = rand(1..1_000_000)
    failure_number = rand(1..1_000_000)

    success = Micro::Case::Result.new.tap { |r| r.__set__(true, success_number, :ok, nil) }

    failure = Micro::Case::Result.new.tap { |r| r.__set__(false, failure_number, :error, build_use_case) }

    assert_equal(success_number, success.value)
    assert_equal(failure_number, failure.value)
  end

  def test_success_hook
    counter = 0
    number = rand(1..1_000_000)
    result = Micro::Case::Result.new.tap { |r| r.__set__(true, number, :valid, nil) }

    result
      .on_failure { raise }
      .on_success(:invalid) { raise }
      .on_success(:valid) { |value| assert_equal(number, value) }
      .on_success(:valid) { counter += 1 }
      .on_success { counter += 1 }

    assert_equal(2, counter)
  end

  def test_failure_hook
    counter = 0
    number = rand(1..1_000_000)
    result = Micro::Case::Result.new.tap { |r| r.__set__(false, number, :invalid, build_use_case) }

    result
      .on_success { raise }
      .on_failure(:invalid) { |value| assert_equal(number, value) }
      .on_failure(:invalid) { counter += 1 }
      .on_failure { counter += 1 }

    assert_equal(2, counter)
  end

  def test_the_invalid_type_error
    result = Micro::Case::Result.new

    assert_raises_with_message(TypeError, 'type must be a Symbol') do
      result.__set__(true, :value, 'type', nil)
    end
  end
end
