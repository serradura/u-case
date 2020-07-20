require 'test_helper'

class Micro::Case::ResultTest < Minitest::Test
  def build_result(success:, value:, type:, use_case: nil)
    result = Micro::Case::Result.new
    result.__set__(success, value, type, use_case || Micro::Case.new({}))
    result
  end

  def failure_result(options = {})
    type = options[:value].is_a?(Exception) ? :exception : :error

    build_result(**{ type: type }.merge(options).merge(success: false))
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

    # ---

    assert_equal(result.transitions, [
      {
        use_case: { class: Micro::Case, attributes: {} },
        success: { type: :ok, value: 1, data: { value: 1 } },
        accessible_attributes: []
      }
    ])
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

    # ---

    assert_equal(result.transitions, [
      {
        use_case: { class: Micro::Case, attributes: {} },
        failure: { type: :error, value: 0, data: { value: 0 } },
        accessible_attributes: []
      }
    ])
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

  def test_the_on_exception_hook
    use_case_instance = Micro::Case.new({})

    # ---

    zero_division_error = ZeroDivisionError.new('divided by 0')

    counter1 = 0
    result1 = failure_result(value: zero_division_error, use_case: use_case_instance)

    result1
      .on_success { raise }
      .on_exception(TypeError) { raise }
      .on_failure(:exception) { counter1 += 1 }
      .on_exception { counter1 += 1 }
      .on_exception(ZeroDivisionError) { counter1 += 1 }

    assert_equal(3, counter1)

    # --

    result1
      .on_failure(:exception) { |value| assert_equal(zero_division_error, value) }
      .on_exception { |value| assert_equal(zero_division_error, value) }
      .on_exception(ZeroDivisionError) { |value| assert_equal(zero_division_error, value) }

    # --

    result1
      .on_failure(:exception) { |value, use_case| assert_equal([zero_division_error, use_case_instance], [value, use_case]) }
      .on_exception { |value, use_case| assert_equal([zero_division_error, use_case_instance], [value, use_case]) }
      .on_exception(ZeroDivisionError) { |value, use_case| assert_equal([zero_division_error, use_case_instance], [value, use_case]) }

    # ---

    counter2 = 0
    result2 = failure_result(value: counter2, use_case: Micro::Case.new({}))

    result2
      .on_success { counter2 +=1 }
      .on_failure(:exception) { counter2 +=1 }
      .on_exception { counter2 +=1 }
      .on_exception(TypeError) { counter2 +=1 }

    assert_equal(0, counter2)
  end

  def test_the_invalid_type_error
    result = Micro::Case::Result.new

    assert_raises_with_message(TypeError, 'type must be a Symbol') do
      result.__set__(true, :value, 'type', nil)
    end
  end

  def test_the_disable_transition_tracking_config
    Micro::Case::Result.disable_transition_tracking

    result = success_result(value: 1, type: :ok)

    assert_predicate(result.transitions, :empty?)

    Micro::Case::Result.class_variable_set(:@@transition_tracking_disabled, false)
  end
end
