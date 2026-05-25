require 'test_helper'

if Gem.loaded_specs.key?('activerecord')
  require 'support/activerecord_setup'
  require 'support/transaction_steps'

  # Internal steps are u-case's third way of building a flow: they live
  # *inside* a single use case's `call!`, chained through `Result#then`
  # (or the `|` pipe alias) with either a Symbol method name, a bound
  # method instance, or a lambda. They are the same composition
  # primitive that flows expose at the outer level — each internal
  # step's Success result becomes the next step's keyword arguments,
  # and each `then` increments `result.transitions`.
  #
  # This file pins down the contract by placing internal-step use
  # cases inside every supported flow wrapper (non-tx and tx), and
  # asserting:
  #
  #   * The accumulated `result.data` ends up identical to a flow
  #     built from the leaf steps, regardless of whether the internal
  #     work was expressed via `.then(:symbol)`, `.then(method(:x))`,
  #     `.then(-> { ... })` or `|`.
  #
  #   * Every internal step contributes a transition. With one
  #     internal-step case (2 internal steps + seed = 3 transitions)
  #     replacing the leaf pair [A, B], a 5-step chain produces
  #     3 (internal) + 3 (outer leaves) = 6 transitions.
  #
  #   * Under `transaction: true`, an internal-step Failure rolls
  #     back the widgets created earlier inside the same internal
  #     chain — proving the transaction boundary spans into internal
  #     steps, not just leaf use cases.
  class Micro::Cases::Flow::InternalStepsInFlowsTest < Minitest::Test
    include TransactionSteps

    def setup
      Widget.delete_all
    end

    INTERNAL_STEP_AB_VARIANTS.each_pair do |variant_name, ab_case|
      # ---------------------------------------------------------------------
      # Non-transactional outer flow: an internal-step case as the first
      # step behaves identically to listing [A, B] directly.
      # ---------------------------------------------------------------------
      NON_TX_WRAPPERS.each_key do |wrapper_name|
        define_method(
          "test_#{wrapper_name}_with_#{variant_name}_internal_steps_accumulates_state"
        ) do
          flow = NON_TX_WRAPPERS.fetch(wrapper_name).call([ab_case, C, D, E])

          result = flow.call(INPUT)

          assert_predicate(result, :success?)
          assert_equal(%w[A B C D E], result.data[:log])
          assert_equal(5, result.data[:counter])
          assert_equal('E', result.data[:e_marker])
          %i[log counter a_marker b_marker c_marker d_marker].each do |key|
            assert_includes(result.accessible_attributes, key)
          end
          assert_equal(%w[A B C D E], Widget.order(:id).pluck(:name))
        end
      end

      # ---------------------------------------------------------------------
      # Same chain under a transactional outer flow: the rollback
      # boundary is irrelevant here (no failure), but the result must
      # remain identical.
      # ---------------------------------------------------------------------
      TX_WRAPPERS.each_key do |tx_wrapper_name|
        define_method(
          "test_#{tx_wrapper_name}_with_#{variant_name}_internal_steps_accumulates_state"
        ) do
          flow = TX_WRAPPERS.fetch(tx_wrapper_name).call([ab_case, C, D, E])

          result = flow.call(INPUT)

          assert_predicate(result, :success?)
          assert_equal(%w[A B C D E], result.data[:log])
          assert_equal(5, result.data[:counter])
          assert_equal(%w[A B C D E], Widget.order(:id).pluck(:name))
        end
      end
    end

    # -----------------------------------------------------------------------
    # Transitions: every internal step contributes one transition entry,
    # interleaved with the outer flow's leaf-step transitions in execution
    # order. The host class is reused for the internal entries (symbol-,
    # method- and lambda-based internal steps all run *as the host use
    # case*, not as separate use case classes); outer leaves report their
    # own class.
    # -----------------------------------------------------------------------
    if ::Micro::Case::Result.transitions_enabled?
      INTERNAL_STEP_AB_VARIANTS.each_pair do |variant_name, ab_case|
        define_method("test_transitions_for_#{variant_name}_internal_steps_inside_flow") do
          flow = Micro::Cases.flow([ab_case, C, D, E])

          result = flow.call(INPUT)
          transitions = result.transitions

          # 3 internal transitions (seed + do_a + do_b) + 3 leaf
          # transitions (C, D, E) == 6.
          assert_equal(6, transitions.size)

          transition_classes = transitions.map { |t| t[:use_case][:class] }
          assert_equal([ab_case, ab_case, ab_case, C, D, E], transition_classes)

          types = transitions.map { |t| (t[:success] || t[:failure])[:type] }
          assert_equal(%i[seeded a_done b_done ok ok ok], types)
        end

        define_method("test_transitions_for_#{variant_name}_internal_steps_inside_tx_flow") do
          flow = Micro::Cases.flow(transaction: true, steps: [ab_case, C, D, E])

          result = flow.call(INPUT)
          transitions = result.transitions

          # The transaction wrapper must not affect transitions at all.
          assert_equal(6, transitions.size)
          assert_equal(
            [ab_case, ab_case, ab_case, C, D, E],
            transitions.map { |t| t[:use_case][:class] }
          )
        end
      end
    end

    # -----------------------------------------------------------------------
    # Failure inside an internal step short-circuits the chain. Under a
    # transactional outer flow, ALL widgets — including the one created
    # by the earlier internal step (`do_a`) — must be rolled back.
    # -----------------------------------------------------------------------
    def test_failure_inside_internal_step_short_circuits_in_non_tx_flow
      flow = Micro::Cases.flow([AFailViaThenSymbols, C, D, E])

      result = flow.call(INPUT)

      assert_predicate(result, :failure?)
      assert_equal(:step_failed, result.type)
      assert_equal(%w[A Fail], result.data[:log])
      # No transaction → both internal-step widgets persist.
      assert_equal(%w[A InternalFail], Widget.order(:id).pluck(:name))
    end

    def test_failure_inside_internal_step_rolls_back_under_tx_flow
      flow = Micro::Cases.flow(transaction: true, steps: [AFailViaThenSymbols, C, D, E])

      result = flow.call(INPUT)

      assert_predicate(result, :failure?)
      assert_equal(:step_failed, result.type)
      assert_equal(0, Widget.count, "expected internal widgets rolled back, got #{Widget.pluck(:name).inspect}")
    end

    def test_failure_inside_internal_step_rolls_back_under_safe_tx_flow
      flow = Micro::Cases.safe_flow(transaction: true, steps: [AFailViaThenSymbols, C, D, E])

      result = flow.call(INPUT)

      assert_predicate(result, :failure?)
      assert_equal(0, Widget.count)
    end

    # -----------------------------------------------------------------------
    # Internal-step case inside a NESTED transactional flow (class wrapper
    # so it isn't flattened). Failure in the inner internal step rolls
    # back everything in the outermost transaction.
    # -----------------------------------------------------------------------
    def test_internal_step_failure_in_nested_tx_class_rolls_back_outer_tx
      inner_class = Class.new(Micro::Case) {
        flow(transaction: true, steps: [TransactionSteps::AFailViaThenSymbols])
      }
      outer = Micro::Cases.flow(transaction: true, steps: [TransactionSteps::C, inner_class, TransactionSteps::D])

      result = outer.call(INPUT)

      assert_predicate(result, :failure?)
      assert_equal(0, Widget.count)
    end

    # -----------------------------------------------------------------------
    # Behavioral parity: an internal-step case as a step produces the
    # SAME result data as expanding [A, B] at the outer level.
    # -----------------------------------------------------------------------
    INTERNAL_STEP_AB_VARIANTS.each_pair do |variant_name, ab_case|
      define_method("test_#{variant_name}_internal_steps_match_leaf_pair_result_data") do
        with_internal = Micro::Cases.flow([ab_case, C, D, E]).call(INPUT)
        Widget.delete_all
        with_leaves = Micro::Cases.flow([A, B, C, D, E]).call(INPUT)

        assert_equal(with_leaves.data, with_internal.data)
        assert_equal(with_leaves.success?, with_internal.success?)
        assert_equal(
          with_leaves.accessible_attributes.sort,
          with_internal.accessible_attributes.sort
        )
      end
    end
  end
end
