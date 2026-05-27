require 'test_helper'

class Micro::Case::SuccessTest < Minitest::Test
  def test_default_args_produce_a_success_result
    result = Micro::Case::Success.new

    assert_predicate(result, :success?)
    refute_predicate(result, :failure?)
    assert_equal(:ok, result.type)
    assert_equal({}, result.data)
    assert_kind_of(::Micro::Case, result.use_case)
  end

  def test_explicit_data_type_and_use_case_override_defaults
    use_case = Micro::Case.send(:new, {})

    result = Micro::Case::Success.new(
      data: { foo: 1 }, type: :created, use_case: use_case
    )

    assert_predicate(result, :success?)
    assert_equal(:created, result.type)
    assert_equal({ foo: 1 }, result.data)
    assert_same(use_case, result.use_case)
  end

  def test_returned_instance_is_a_plain_result_not_a_subclass
    result = Micro::Case::Success.new

    assert_equal(::Micro::Case::Result, result.class)
    assert_kind_of(::Micro::Case::Result, result)
  end

  def test_non_symbol_type_raises_the_curated_check_error
    assert_raises(Micro::Case::Error::InvalidResultType) do
      Micro::Case::Success.new(type: 'ok')
    end
  end

  def test_non_micro_case_use_case_raises_the_curated_check_error
    assert_raises(Micro::Case::Error::InvalidUseCase) do
      Micro::Case::Success.new(use_case: Object.new)
    end
  end

  def test_nil_data_raises_the_curated_check_error
    assert_raises(Micro::Case::Error::InvalidResult) do
      Micro::Case::Success.new(data: nil)
    end
  end

  def test_transitions_log_shape_matches_a_real_one_step_use_case
    result = Micro::Case::Success.new(data: { x: 1 })

    if Micro::Case::Result.transitions_enabled?
      assert_equal(1, result.transitions.size)
    else
      assert_equal([], result.transitions)
    end
  end

  def test_default_use_case_is_memoised_across_calls
    a = Micro::Case::Success.new
    b = Micro::Case::Success.new

    assert_same(a.use_case, b.use_case)
  end

  def test_to_yield_returns_a_wrapper_in_initial_state
    wrapper = Micro::Case::Success.to_yield(data: { x: 1 })

    assert_kind_of(Micro::Case::Result::Wrapper, wrapper)
    assert_same(Kind::Undefined, wrapper.output)
  end

  def test_to_yield_lets_a_block_consumer_drive_it
    wrapper = Micro::Case::Success.to_yield(data: { x: 1 })

    wrapper.success { |result| result[:x] }

    assert_equal(1, wrapper.output)
  end

  def test_to_yield_failure_branch_is_a_no_op_for_a_success_wrapper
    wrapper = Micro::Case::Success.to_yield(data: { x: 1 })

    wrapper.failure { |_| raise 'should not fire' }

    assert_same(Kind::Undefined, wrapper.output)
  end

  def test_to_yield_respects_the_type_filter
    wrapper = Micro::Case::Success.to_yield(type: :created, data: { x: 1 })

    wrapper.success(:other) { |_| raise 'should not fire' }
    assert_same(Kind::Undefined, wrapper.output)

    wrapper.success(:created) { |result| result[:x] }
    assert_equal(1, wrapper.output)
  end
end
