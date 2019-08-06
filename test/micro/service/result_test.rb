require 'test_helper'

class Micro::Service::ResultTest < Minitest::Test
  def test_success_result
    result = Micro::Service::Result.new(success: true)

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
    result = Micro::Service::Result.new(success: false)

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

  def test_success_factory
    err = assert_raises(ArgumentError) do
      Micro::Service::Result::Success()
    end

    assert_equal('missing keyword: value', err.message)

    # ---

    result = Micro::Service::Result::Success(value: :value, type: :foo)

    assert(result.success?)
    assert_equal(:foo, result.type)
    assert_instance_of(Micro::Service::Result, result)
  end

  def test_failure_factory
    err = assert_raises(ArgumentError) do
      Micro::Service::Result::Failure()
    end

    assert_equal('missing keyword: value', err.message)

  # ---

    result = Micro::Service::Result::Failure(value: :value, type: :bar)

    assert(result.failure?)
    assert_equal(:bar, result.type)
    assert_instance_of(Micro::Service::Result, result)
  end

  def test_value
    success_number = rand(1..1_000_000)
    failure_number = rand(1..1_000_000)

    success = Micro::Service::Result.new(success: true, value: success_number)

    failure = Micro::Service::Result.new(success: true, value: failure_number)

    assert_equal(success_number, success.value)
    assert_equal(failure_number, failure.value)
  end

  def test_success_hook
    counter = 0
    number = rand(1..1_000_000)
    result = Micro::Service::Result::Success(value: number, type: :valid)

    result
      .on_failure { raise }
      .on_success(:invalid) { raise }
      .on_success(:valid) { |value| assert_equal(number, value) }
      .on_success { counter += 1 }

    assert_equal(1, counter)
  end


  def test_failure_hook
    counter = 0
    number = rand(1..1_000_000)
    result = Micro::Service::Result::Failure(value: number, type: :valid)

    result
      .on_success { raise }
      .on_failure(:invalid) { raise }
      .on_failure(:valid) { |value| assert_equal(number, value) }
      .on_failure { counter += 1 }

    assert_equal(1, counter)
  end
end
