require 'test_helper'

class Micro::Service::ResultTest < Minitest::Test
  def build_service
    Micro::Service::Base.new({})
  end

  def test_success_result
    result = Micro::Service::Result.new
    result.__set__(true, 1, :ok, nil)

    assert result.success?
    refute result.failure?

    assert_equal(1, result.value)
    err = assert_raises(Micro::Service::Result::InvalidAccessToTheServiceObject) { result.service }
    assert_equal('only a failure result can access its service object', err.message)

    # ---

    assert_equal(
      result,
      result
        .on_failure { raise }
        .on_success { assert(true) }
        .on_success { |value| assert_equal(1, value) }
    )

    # ---

    assert_instance_of(Micro::Service::Result, result)
  end

  def test_failure_result
    service = build_service

    result = Micro::Service::Result.new
    result.__set__(false, 0, :error, service)

    refute result.success?
    assert result.failure?

    assert_equal(0, result.value)
    assert_same(service, result.service)

    # ---

    assert_equal(
      result,
      result
        .on_failure { assert(true) }
        .on_failure { |value| assert_equal(0, value) }
        .on_failure { |_value, serv| assert_same(serv, service) }
        .on_success { raise }
    )

    # ---

    assert_instance_of(Micro::Service::Result, result)
  end

  def test_value
    success_number = rand(1..1_000_000)
    failure_number = rand(1..1_000_000)

    success = Micro::Service::Result.new.tap { |r| r.__set__(true, success_number, :ok, nil) }

    failure = Micro::Service::Result.new.tap { |r| r.__set__(false, failure_number, :error, build_service) }

    assert_equal(success_number, success.value)
    assert_equal(failure_number, failure.value)
  end

  def test_success_hook
    counter = 0
    number = rand(1..1_000_000)
    result = Micro::Service::Result.new.tap { |r| r.__set__(true, number, :valid, nil) }

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
    result = Micro::Service::Result.new.tap { |r| r.__set__(false, number, :invalid, build_service) }

    result
      .on_success { raise }
      .on_failure(:invalid) { |value| assert_equal(number, value) }
      .on_failure(:invalid) { counter += 1 }
      .on_failure { counter += 1 }

    assert_equal(2, counter)
  end

  def test_the_invalid_type_error
    type = nil
    result = Micro::Service::Result.new

    err = assert_raises(TypeError) { result.__set__(true, :value, type, nil) }
    assert_equal('type must be a Symbol', err.message)
  end
end
