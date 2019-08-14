require 'test_helper'

class Micro::Service::ResultTest < Minitest::Test
  def test_success_result
    result = Micro::Service::Result.new
    result.__set__(true, 1, nil)

    assert result.success?
    refute result.failure?

    # ---

    assert_equal(
      result,
      result
        .on_failure { raise }
        .on_success { assert(true) }
    )

    # ---

    assert_instance_of(Micro::Service::Result, result)
  end

  def test_failure_result
    result = Micro::Service::Result.new
    result.__set__(false, 1, nil)

    refute result.success?
    assert result.failure?

    # ---

    assert_equal(
      result,
      result
        .on_failure { assert(true) }
        .on_success { raise }
    )

    # ---

    assert_instance_of(Micro::Service::Result, result)
  end

  def test_value
    success_number = rand(1..1_000_000)
    failure_number = rand(1..1_000_000)

    success = Micro::Service::Result.new.tap { |r| r.__set__(true, success_number, nil) }

    failure = Micro::Service::Result.new.tap { |r| r.__set__(false, failure_number, nil) }

    assert_equal(success_number, success.value)
    assert_equal(failure_number, failure.value)
  end

  def test_success_hook
    counter = 0
    number = rand(1..1_000_000)
    result = Micro::Service::Result.new.tap { |r| r.__set__(true, number, :valid) }

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
    result = Micro::Service::Result.new.tap { |r| r.__set__(false, number, :invalid) }

    result
      .on_success { raise }
      .on_failure(:invalid) { |value| assert_equal(number, value) }
      .on_failure(:invalid) { counter += 1 }
      .on_failure { counter += 1 }

    assert_equal(2, counter)
  end
end
