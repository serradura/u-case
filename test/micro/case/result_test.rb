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
    use_case = Micro::Case.new({})

    result = success_result(value: { a: 1, b: 2 }, type: :ok, use_case: use_case)

    assert_predicate(result, :success?)
    assert_equal(:success, result.to_sym)
    assert_equal(1, result.value[:a])

    assert_same(use_case, result.use_case)

    # ---

    assert_same(
      result,
      result
        .on_success { assert(true) }
        .on_success { |data| assert_equal(1, data.value[:a]) }
        .on_success { |data, _ucase| assert_equal(1, data[:a]) }
        .on_success { |_data, ucase| assert_same(ucase, use_case) }
        .on_success { |(data, _type)| assert_equal(1, data[:a]) }
        .on_failure { raise }
    )

    # ---

    assert_instance_of(Micro::Case::Result, result)

    # ---

    if ::Micro::Case::Result.transitions_enabled?
      assert_equal(result.transitions, [
        {
          use_case: { class: Micro::Case, attributes: {} },
          success: { type: :ok, result: { a: 1, b: 2 } },
          accessible_attributes: []
        }
      ])
    end

    # ---

    assert_equal(1, result[:a])

    assert_equal([1], result.values_at(:a))
    assert_equal([2, 1], result.values_at(:b, :a))

    # ---

    assert(result.key?(:a))
    refute(result.key?(:c))

    # ---

    assert(result.value?(2))
    refute(result.value?(10))

    # ---

    assert_equal({ a: 1, b: 2 }, result.slice(:a, :b, :c))
    assert_equal({}, result.slice(:c))
  end

  def test_failure_result
    use_case = Micro::Case.new({})

    result = failure_result(value: { a: 0, b: -1 }, type: :error, use_case: use_case)

    refute_predicate(result, :success?)
    assert_predicate(result, :failure?)

    assert_equal(:failure, result.to_sym)
    assert_equal(0, result.value[:a])
    assert_same(use_case, result.use_case)

    # ---

    assert_same(
      result,
      result
        .on_failure { assert(true) }
        .on_failure { |data| assert_equal(0, data.value[:a]) }
        .on_failure { |data, _ucase| assert_equal(0, data[:a]) }
        .on_failure { |_data, ucase| assert_same(ucase, use_case) }
        .on_failure { |(data, _type)| assert_equal(0, data[:a]) }
        .on_success { raise }
    )

    # ---

    assert_instance_of(Micro::Case::Result, result)

    # ---

    if ::Micro::Case::Result.transitions_enabled?
      assert_equal(result.transitions, [
        {
          use_case: { class: Micro::Case, attributes: {} },
          failure: { type: :error, result: { a: 0, b: -1 } },
          accessible_attributes: []
        }
      ])
    end

    # ---

    assert_equal(0, result[:a])

    assert_equal([0], result.values_at(:a))
    assert_equal([-1, 0], result.values_at(:b, :a))
  end

  def test_the_result_value
    success_number = rand(1..1_000_000)
    success = success_result(value: { number: success_number }, type: :ok, use_case: nil)

    failure_number = rand(1..1_000_000)
    failure = failure_result(value: { number: failure_number }, type: :error, use_case: Micro::Case.new({}))

    assert_equal(success_number, success.value[:number])
    assert_equal(failure_number, failure.value[:number])
  end

  def test_the_on_success_hook
    counter = 0
    number = rand(1..1_000_000)
    result = success_result(value: { number: number }, type: :valid, use_case: nil)

    result
      .on_failure { raise }
      .on_success(:invalid) { raise }
      .on_success(:valid) { |value| assert_equal(number, value[:number]) }
      .on_success(:valid) { counter += 1 }
      .on_success { counter += 1 }

    assert_equal(2, counter)
  end

  def test_the_on_failure_hook
    counter = 0
    number = rand(1..1_000_000)
    result = failure_result(value: { number: number }, type: :invalid, use_case: Micro::Case.new({}))

    result
      .on_success { raise }
      .on_failure(:invalid) { |value| assert_equal(number, value[:number]) }
      .on_failure(:invalid) { counter += 1 }
      .on_failure { counter += 1 }

    assert_equal(2, counter)
  end

  def test_the_on_unknown_hook
    number = rand(1..1_000_000)

    failure_result = failure_result(value: { number: number }, type: :not_mapped, use_case: Micro::Case.new({}))

    failure_result
      .on_failure(:a) { raise }
      .on_unknown { |data| assert_equal(number, data[:number]) }

    assert_predicate(failure_result, :unknown?)

    # ---

    success_result = success_result(value: { number: number }, type: :not_mapped, use_case: Micro::Case.new({}))

    success_result
      .on_success(:b) { raise }
      .on_unknown { |data| assert_equal(number, data[:number]) }

    assert_predicate(success_result, :unknown?)
  end

  def test_the_on_unknown_hook_exclusivity

    failure_counter = 0
    failure_result = failure_result(value: {}, type: :not_mapped, use_case: Micro::Case.new({}))

    failure_result
      .on_failure { failure_counter += 1 }
      .on_unknown { failure_counter += 1 }

    assert_equal(1, failure_counter)
    refute_predicate(failure_result, :unknown?)

    # ---

    success_counter = 0
    success_result = success_result(value: {}, type: :not_mapped, use_case: Micro::Case.new({}))

    success_result
      .on_success { success_counter += 1 }
      .on_unknown { success_counter += 1 }

    assert_equal(1, success_counter)
    refute_predicate(failure_result, :unknown?)

    # ---

    unknown_counter = 0
    unknown_result = success_result(value: {}, type: :not_mapped, use_case: Micro::Case.new({}))

    unknown_result
      .on_unknown { unknown_counter += 1 }
      .on_unknown { unknown_counter += 1 }

    assert_equal(2, unknown_counter)
  end

  def test_the_output_of_a_failure_hook_without_a_defined_type
    acc = 0
    number = rand(1..1_000_000)
    result = failure_result(value: { number: number }, type: :invalid, use_case: Micro::Case.new({}))

    result
      .on_failure(:invalid) { |value| acc += value[:number] }
      .on_failure { |data| acc += data.value[:number] if data.type == :invalid }
      .on_failure { |(value, type)| acc += value[:number] if type == :invalid }
      .on_failure { |(value, _type)| acc += value[:number] }
      .on_failure { |(value, *)| acc += value[:number] }

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
      .on_failure(:exception) { |value| assert_equal(zero_division_error, value[:exception]) }
      .on_exception { |value| assert_equal(zero_division_error, value[:exception]) }
      .on_exception(ZeroDivisionError) { |value| assert_equal(zero_division_error, value[:exception]) }

    # --

    result1
      .on_failure(:exception) { |value, use_case| assert_equal([zero_division_error, use_case_instance], [value[:exception], use_case]) }
      .on_exception { |value, use_case| assert_equal([zero_division_error, use_case_instance], [value[:exception], use_case]) }
      .on_exception(ZeroDivisionError) { |value, use_case| assert_equal([zero_division_error, use_case_instance], [value[:exception], use_case]) }

    # ---

    counter2 = 0
    result2 = failure_result(value: {}, use_case: Micro::Case.new({}))

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

  class Add2ToAllNumbers < Micro::Case
    attribute :numbers

    def call!
      convert_text_to_numbers
        .then(method(:add_2))
    end

    private

      def convert_text_to_numbers
        if numbers.all? { |value| String(value) =~ /\d+/ }
          Success result: { numbers: numbers.map(&:to_i) }
        else
          Failure result: { numbers: 'must contain only numeric types' }
        end
      end

      def add_2(data)
        Success result: { numbers: data[:numbers].map { |number| number + 2 } }
      end
  end

  def test_the_result_when_transitions_are_disabled
    return if ::Micro::Case::Result.transitions_enabled?

    result = success_result(value: { number: 1 }, type: :ok)

    assert_predicate(result.transitions, :empty?)

    # ---

    result1 = Add2ToAllNumbers.call(numbers: %w[1 1 2 2 3 4])

    assert_success_result(result1, value: { numbers: [3, 3, 4, 4, 5, 6] })

    result2 = Add2ToAllNumbers.call(numbers: %w[1 1 2 2 c 4])

    assert_failure_result(result2, value: { numbers: 'must contain only numeric types' })
  end
end
