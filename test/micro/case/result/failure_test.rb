require 'test_helper'

class Micro::Case::Result::FailureTest < Minitest::Test
  def test_default_args_produce_a_failure_result
    result = Micro::Case::Result::Failure.new

    assert_predicate(result, :failure?)
    refute_predicate(result, :success?)
    assert_equal(:error, result.type)
    assert_equal({}, result.data)
    assert_kind_of(::Micro::Case, result.use_case)
  end

  def test_explicit_data_type_and_use_case_override_defaults
    use_case = Micro::Case.send(:new, {})

    result = Micro::Case::Result::Failure.new(
      data: { errors: %w[bad] }, type: :invalid, use_case: use_case
    )

    assert_predicate(result, :failure?)
    assert_equal(:invalid, result.type)
    assert_equal({ errors: %w[bad] }, result.data)
    assert_same(use_case, result.use_case)
  end

  def test_returned_instance_is_a_plain_result_not_a_subclass
    result = Micro::Case::Result::Failure.new

    assert_equal(::Micro::Case::Result, result.class)
    assert_kind_of(::Micro::Case::Result, result)
  end

  def test_non_symbol_type_raises_the_curated_check_error
    assert_raises(Micro::Case::Error::InvalidResultType) do
      Micro::Case::Result::Failure.new(type: 'error')
    end
  end

  def test_non_micro_case_use_case_raises_the_curated_check_error
    assert_raises(Micro::Case::Error::InvalidUseCase) do
      Micro::Case::Result::Failure.new(use_case: Object.new)
    end
  end

  def test_nil_data_raises_the_curated_check_error
    assert_raises(Micro::Case::Error::InvalidResult) do
      Micro::Case::Result::Failure.new(data: nil)
    end
  end

  def test_transitions_log_shape_matches_a_real_one_step_use_case
    result = Micro::Case::Result::Failure.new(data: { x: 1 })

    if Micro::Case::Result.transitions_enabled?
      assert_equal(1, result.transitions.size)
    else
      assert_equal([], result.transitions)
    end
  end

  def test_default_use_case_is_memoised_across_calls
    a = Micro::Case::Result::Failure.new
    b = Micro::Case::Result::Failure.new

    assert_same(a.use_case, b.use_case)
  end

  def test_to_yield_returns_a_wrapper_in_initial_state
    wrapper = Micro::Case::Result::Failure.to_yield(data: { x: 1 })

    assert_kind_of(Micro::Case::Result::Wrapper, wrapper)
    assert_same(Kind::Undefined, wrapper.output)
  end

  def test_to_yield_lets_a_block_consumer_drive_it
    wrapper = Micro::Case::Result::Failure.to_yield(data: { x: 1 })

    wrapper.failure { |result| result[:x] }

    assert_equal(1, wrapper.output)
  end

  def test_to_yield_success_branch_is_a_no_op_for_a_failure_wrapper
    wrapper = Micro::Case::Result::Failure.to_yield(data: { x: 1 })

    wrapper.success { |_| raise 'should not fire' }

    assert_same(Kind::Undefined, wrapper.output)
  end

  def test_to_yield_respects_the_type_filter
    wrapper = Micro::Case::Result::Failure.to_yield(type: :invalid, data: { x: 1 })

    wrapper.failure(:other) { |_| raise 'should not fire' }
    assert_same(Kind::Undefined, wrapper.output)

    wrapper.failure(:invalid) { |result| result[:x] }
    assert_equal(1, wrapper.output)
  end
end
