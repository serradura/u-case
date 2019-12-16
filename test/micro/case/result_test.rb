require 'test_helper'

class Micro::Case::ResultTest < Minitest::Test
  def build_result(success:, value:, type:, use_case: nil)
    result = Micro::Case::Result.new
    result.__set__(success, value, type, use_case || Micro::Case.new({}))
    result
  end

  def failure_result(options = {})
    build_result(**{ type: :error }.merge(options).merge(success: false))
  end

  def success_result(options = {})
    build_result(**{ type: :ok }.merge(options).merge(success: true))
  end

  def test_success_result
    result = success_result(value: 1, type: :ok)

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
        .on_success { |(value, _type)| assert_equal(1, value) }
    )

    # ---

    assert_instance_of(Micro::Case::Result, result)
  end

  def test_failure_result
    use_case = Micro::Case.new({})

    result = failure_result(value: 0, type: :error, use_case: use_case)

    refute_predicate(result, :success?)
    assert_predicate(result, :failure?)

    assert_equal(0, result.value)
    assert_same(use_case, result.use_case)

    # ---

    assert_equal(
      result,
      result
        .on_failure { assert(true) }
        .on_failure { |data| assert_equal(0, data.value) }
        .on_failure { |_data, ucase| assert_same(ucase, use_case) }
        .on_success { raise }
    )

    # ---

    assert_instance_of(Micro::Case::Result, result)
  end

  def test_the_result_value
    success_number = rand(1..1_000_000)
    success = success_result(value: success_number, type: :ok, use_case: nil)

    failure_number = rand(1..1_000_000)
    failure = failure_result(value: failure_number, type: :error, use_case: Micro::Case.new({}))

    assert_equal(success_number, success.value)
    assert_equal(failure_number, failure.value)
  end

  def test_the_on_success_hook
    counter = 0
    number = rand(1..1_000_000)
    result = success_result(value: number, type: :valid, use_case: nil)

    result
      .on_failure { raise }
      .on_success(:invalid) { raise }
      .on_success(:valid) { |value| assert_equal(number, value) }
      .on_success(:valid) { counter += 1 }
      .on_success { counter += 1 }

    assert_equal(2, counter)
  end

  def test_the_on_failure_hook
    counter = 0
    number = rand(1..1_000_000)
    result = failure_result(value: number, type: :invalid, use_case: Micro::Case.new({}))

    result
      .on_success { raise }
      .on_failure(:invalid) { |value| assert_equal(number, value) }
      .on_failure(:invalid) { counter += 1 }
      .on_failure { counter += 1 }

    assert_equal(2, counter)
  end

  def test_the_result_data_of_a_failure_hook_without_a_type
    acc = 0
    number = rand(1..1_000_000)
    result = failure_result(value: number, type: :invalid, use_case: Micro::Case.new({}))

    result
      .on_failure(:invalid) { |value| acc += value }
      .on_failure { |data| acc += data.value if data.type == :invalid }
      .on_failure { |(value, type)| acc += value if type == :invalid }
      .on_failure { |(value, _type)| acc += value }
      .on_failure { |(value, *)| acc += value }

    assert_equal(number * 5, acc)
  end

  def test_the_invalid_type_error
    result = Micro::Case::Result.new

    assert_raises_with_message(TypeError, 'type must be a Symbol') do
      result.__set__(true, :value, 'type', nil)
    end
  end

  def test_the_data_method
    use_case = Micro::Case.new({})

    # ---

    result0 = success_result(value: 0, type: :ok)

    assert_equal({ value: 0 }, result0.data)
    assert_equal(result0.data, result0.to_h)
    assert_equal(0, result0[:value])

    # ---

    result1 = failure_result(value: 1, type: :error, use_case: use_case)

    assert_equal({ value: 1 }, result1.data)
    assert_equal(result1.data, result1.to_h)
    assert_equal(1, result1[:value])

    assert_predicate(result1, :failure?)

    result1.on_failure do |result|
      assert_equal({ value: 1 }, result.data)
      assert_equal(result1.data, result1.to_h)
      assert_equal(1, result1[:value])
    end

    # ---

    result2 = failure_result(value: :invalid_data, type: :invalid_data, use_case: use_case)

    assert_equal({ invalid_data: true }, result2.data)
    assert_equal(result2.data, result2.to_h)
    assert_equal(true, result2[:invalid_data])

    assert_predicate(result2, :failure?)

    result2.on_failure do |result|
      assert_equal({ invalid_data: true }, result.data)
      assert_equal(result2.data, result2.to_h)
      assert_equal(true, result2[:invalid_data])
    end

    # ---

    result3 = failure_result(value: { one: 1, two: 2 }, type: :error, use_case: use_case)

    assert_equal({ one: 1, two: 2 }, result3.data)

    assert_predicate(result3, :failure?)

    result3.on_failure do |result|
      assert_equal({ one: 1, two: 2 }, result.data)
      assert_equal(result3.data, result3.to_h)
      assert_equal(1, result3[:one])
      assert_equal(2, result3[:two])
    end
  end
end
