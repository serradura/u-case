require 'test_helper'

class Micro::Case::Result::ThenExposeTest < Minitest::Test
  class NoopUseCase < Micro::Case
    def call!; Success(); end
  end

  def build_result(success:, value:, type:, use_case: nil)
    result = Micro::Case::Result.new
    result.__set__(success, value, type, use_case || NoopUseCase.send(:new, {}))
    result
  end

  def success_result(options = {})
    build_result(**{ type: :ok }.merge(options).merge(success: true))
  end

  def failure_result(options = {})
    build_result(**{ type: :error }.merge(options).merge(success: false))
  end

  # ----- Call shapes -----

  def test_two_arg_form_with_array_keys
    result = success_result(value: { a: 1, b: 2, c: 3 }).then_expose(:my_type, [:a, :b])

    assert_success_result(result, type: :my_type, value: { a: 1, b: 2 })
  end

  def test_two_arg_form_with_symbol_key
    result = success_result(value: { a: 1, b: 2 }).then_expose(:my_type, :a)

    assert_success_result(result, type: :my_type, value: { a: 1 })
  end

  def test_single_array_form_defaults_to_data_exposed
    result = success_result(value: { a: 1, b: 2, c: 3 }).then_expose([:a, :b])

    assert_success_result(result, type: :data_exposed, value: { a: 1, b: 2 })
  end

  # ----- Argument validation -----

  def test_no_arg_call_raises_argument_error
    assert_raises(ArgumentError) { success_result(value: { a: 1 }).then_expose }
  end

  def test_single_symbol_arg_raises_argument_error
    assert_raises_with_message(
      ArgumentError,
      'keys must be a non-empty Array of Symbols'
    ) { success_result(value: { a: 1 }).then_expose(:a) }
  end

  def test_empty_array_single_arg_raises
    assert_raises_with_message(
      ArgumentError,
      'keys must be a non-empty Array of Symbols'
    ) { success_result(value: { a: 1 }).then_expose([]) }
  end

  def test_empty_array_two_arg_raises
    assert_raises_with_message(
      ArgumentError,
      'keys must be a non-empty Array of Symbols'
    ) { success_result(value: { a: 1 }).then_expose(:my_type, []) }
  end

  def test_non_symbol_elements_single_arg_raises
    assert_raises_with_message(
      ArgumentError,
      'keys must be a non-empty Array of Symbols'
    ) { success_result(value: { a: 1 }).then_expose([:a, 'b']) }
  end

  def test_non_symbol_elements_two_arg_raises
    assert_raises_with_message(
      ArgumentError,
      'keys must be a non-empty Array of Symbols'
    ) { success_result(value: { a: 1 }).then_expose(:my_type, ['a']) }
  end

  def test_non_symbol_type_two_arg_raises
    assert_raises_with_message(
      ArgumentError,
      'type must be a Symbol'
    ) { success_result(value: { a: 1 }).then_expose('my_type', [:a]) }
  end

  # ----- Failure short-circuit -----

  def test_failure_short_circuit_returns_self_unchanged
    failure = failure_result(value: { reason: 'nope' }, type: :something_failed)

    original_type = failure.type
    original_data = failure.data
    original_use_case = failure.use_case
    original_transitions = failure.transitions

    returned = failure.then_expose(:should_not_apply, [:reason])

    assert_same(failure, returned)
    assert_equal(original_type, failure.type)
    assert_equal(original_data, failure.data)
    assert_same(original_use_case, failure.use_case)
    assert_equal(original_transitions, failure.transitions)
  end

  # ----- Source: accessible_attributes -----

  class FindUser < Micro::Case
    attribute :email

    def call!
      Success result: { user: { id: 1, email: email } }
    end
  end

  def test_key_sourced_from_accessible_attributes_only
    # `email` is the use case's attribute (accessible_attributes), but it's
    # NOT in the result data (accumulated_data). then_expose must still
    # be able to pick it up.
    result = FindUser.call(email: 'a@b').then_expose(:user_found, [:email])

    assert_success_result(result, type: :user_found, value: { email: 'a@b' })
  end

  # ----- Collision precedence: accumulated wins over accessible -----

  class EchoFoo < Micro::Case
    attribute :foo

    def call!
      Success result: { foo: 'updated' }
    end
  end

  def test_collision_precedence_accumulated_data_wins
    result = EchoFoo.call(foo: 'original').then_expose(:exposed_foo, [:foo])

    assert_success_result(result, type: :exposed_foo, value: { foo: 'updated' })
  end

  # ----- Missing-key error -----

  def test_missing_key_raises_invalid_result_exposure
    err = assert_raises(Micro::Case::Error::InvalidResultExposure) do
      success_result(value: { a: 1, b: 2 }).then_expose(:my_type, [:missing])
    end

    assert_match(/:missing/, err.message)
    assert_match(/Available to expose/, err.message)
    assert_match(/:a/, err.message)
    assert_match(/:b/, err.message)
  end

  def test_invalid_result_exposure_is_a_kind_of_key_error
    assert(Micro::Case::Error::InvalidResultExposure < ::KeyError)

    raised_via_key_error_rescue = false

    begin
      success_result(value: { a: 1 }).then_expose(:my_type, [:missing])
    rescue ::KeyError
      raised_via_key_error_rescue = true
    end

    assert(raised_via_key_error_rescue, 'InvalidResultExposure should be rescuable as ::KeyError')
  end

  # ----- then_return alias -----

  def test_then_return_alias_two_arg_array
    result = success_result(value: { a: 1, b: 2 }).then_return(:my_type, [:a, :b])

    assert_success_result(result, type: :my_type, value: { a: 1, b: 2 })
  end

  def test_then_return_alias_two_arg_symbol
    result = success_result(value: { a: 1 }).then_return(:my_type, :a)

    assert_success_result(result, type: :my_type, value: { a: 1 })
  end

  def test_then_return_alias_single_array
    result = success_result(value: { a: 1, b: 2 }).then_return([:a, :b])

    assert_success_result(result, type: :data_exposed, value: { a: 1, b: 2 })
  end

  def test_then_return_alias_failure_short_circuit
    failure = failure_result(value: { reason: 'nope' }, type: :nope)

    returned = failure.then_return(:should_not_apply, [:reason])

    assert_same(failure, returned)
    assert_equal(:nope, failure.type)
  end

  # ----- Transitions -----

  def test_then_expose_records_transition_when_enabled
    skip 'transitions are disabled' unless Micro::Case::Result.transitions_enabled?

    result = FindUser.call(email: 'a@b').then_expose(:user_found, [:email])

    transitions = result.transitions

    assert_equal(2, transitions.size)

    exposure_transition = transitions.last
    assert_equal(:user_found, exposure_transition[:success][:type])
    assert_equal({ email: 'a@b' }, exposure_transition[:success][:result])
  end

  def test_then_expose_records_no_transition_when_disabled
    skip 'transitions are enabled' if Micro::Case::Result.transitions_enabled?

    result = FindUser.call(email: 'a@b').then_expose(:user_found, [:email])

    assert_equal([], result.transitions)
    assert_success_result(result, type: :user_found, value: { email: 'a@b' })
  end

  # ----- Accumulated data threading -----

  class Append < Micro::Case
    attributes :base, :tail

    def call!
      Success result: { joined: "#{base}-#{tail}" }
    end
  end

  def test_exposed_data_is_visible_to_subsequent_then_chained_use_cases
    # First step accumulates several keys; then_expose narrows to one,
    # but because __set__ merges the exposed slice into @__accumulated_data,
    # a subsequent .then(Append) should still see :base from the merged map.
    result =
      FindUser
        .call(email: 'a@b')
        .then_expose(:user_with_email, [:email])
        .then(Append, base: 'x', tail: 'y')

    assert_success_result(result, value: { joined: 'x-y' })
  end

  # ----- disable_runtime_checks mode -----

  def test_then_expose_works_with_checks_disabled
    Micro::Case.config { |c| c.disable_runtime_checks = true }

    result = success_result(value: { a: 1, b: 2 }).then_expose(:my_type, [:a, :b])

    assert_equal(:my_type, result.type)
    assert_equal({ a: 1, b: 2 }, result.data)
    assert_predicate(result, :success?)
  ensure
    Micro::Case.config { |c| c.disable_runtime_checks = false }
  end

  # ----- Producer-side contract bypass (by design) -----

  class StrictContract < Micro::Case
    attribute :email

    results do |on|
      on.success(result: [:user])
    end

    def call!
      Success result: { user: { id: 1, email: email } }
    end
  end

  def test_then_expose_bypasses_producer_results_contract
    # The use case declares only `:ok` as a success type, but then_expose
    # re-tags with `:user_created` — which is NOT in the contract. This
    # must succeed (no UnexpectedResultType) because then_expose runs
    # downstream of the contract check.
    result = StrictContract.call(email: 'a@b').then_expose(:user_created, [:user])

    assert_predicate(result, :success?)
    assert_equal(:user_created, result.type)
    assert_equal({ user: { id: 1, email: 'a@b' } }, result.data)
  end

  def test_then_expose_default_type_also_bypasses_contract
    # Same idea with the default :data_exposed type — also not declared
    # in the contract, must not raise.
    result = StrictContract.call(email: 'a@b').then_expose([:user])

    assert_predicate(result, :success?)
    assert_equal(:data_exposed, result.type)
    assert_equal({ user: { id: 1, email: 'a@b' } }, result.data)
  end
end
