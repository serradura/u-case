require 'test_helper'

class Micro::Cases::Flow::TransactionKwargTest < Minitest::Test
  class Increment < Micro::Case
    attribute :count
    def call!; Success result: { count: count + 1 }; end
  end

  class Fail < Micro::Case
    def call!; Failure(:boom); end
  end

  def test_steps_kwarg_is_equivalent_to_positional_collection
    flow = Micro::Cases.flow(steps: [Increment, Increment])

    result = flow.call(count: 0)

    assert_predicate(result, :success?)
    assert_equal(2, result[:count])
  end

  def test_passing_both_positional_and_steps_raises
    error = assert_raises(ArgumentError) do
      Micro::Cases.flow([Increment], steps: [Increment])
    end

    assert_match(/positional collection OR `steps:`/, error.message)
  end

  def test_safe_flow_supports_steps_kwarg
    flow = Micro::Cases.safe_flow(steps: [Increment])

    result = flow.call(count: 0)

    assert_predicate(result, :success?)
    assert_equal(1, result[:count])
  end

  def test_transaction_true_without_activerecord_raises_on_call
    flow = Micro::Cases.flow(transaction: true, steps: [Increment])

    if defined?(::ActiveRecord::Base)
      result = flow.call(count: 0)
      assert_predicate(result, :success?)
      assert_equal(1, result[:count])
    else
      error = assert_raises(Micro::Cases::Error::TransactionAdapterMissing) do
        flow.call(count: 0)
      end
      assert_match(/ActiveRecord/, error.message)
    end
  end

  def test_transaction_nil_is_a_noop
    flow = Micro::Cases.flow(transaction: nil, steps: [Increment])

    result = flow.call(count: 0)

    assert_predicate(result, :success?)
    assert_equal(1, result[:count])
  end

  def test_class_level_flow_supports_steps_kwarg
    klass = Class.new(Micro::Case) { flow(steps: [Increment, Increment]) }

    result = klass.call(count: 1)

    assert_predicate(result, :success?)
    assert_equal(3, result[:count])
  end

  def test_class_level_flow_rejects_mixing_positional_and_steps
    error = assert_raises(ArgumentError) do
      Class.new(Micro::Case) { flow(Increment, steps: [Increment]) }
    end

    assert_match(/positional steps OR `steps:`/, error.message)
  end

  def test_inspect_mentions_transaction_when_set
    flow = Micro::Cases.flow(transaction: true, steps: [Increment])

    assert_match(/transaction=true/, flow.inspect)
  end

  def test_unsupported_transaction_value_raises
    error = assert_raises(ArgumentError) do
      Micro::Cases.flow(transaction: :sequel, steps: [Increment])
    end

    assert_match(/transaction: :sequel is not supported/, error.message)
  end
end
