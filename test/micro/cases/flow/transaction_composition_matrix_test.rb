require 'test_helper'

if Gem.loaded_specs.key?('activerecord')
  require 'support/activerecord_setup'
  require 'support/transaction_steps'

  # Stress test: combine `transaction: true` flows with regular flows in
  # every supported composition shape and verify that
  #
  #   1. The observable result (`result.data`, `result.type`,
  #      `result.transitions`, `result.accessible_attributes`) is
  #      **identical** to a regular flow built from the same steps.
  #      The transaction kwarg only affects side-effects.
  #
  #   2. A `Failure` produced at any nesting level rolls back every
  #      `ActiveRecord` write performed *inside the nearest enclosing
  #      `transaction: true` flow*.
  #
  #   3. Safe transactional wrappers rescue unexpected exceptions raised
  #      by inner steps, surface them as `:exception` failures, AND roll
  #      back the side-effects performed before the raise.
  #
  #   4. Nesting behavior: `Micro::Cases.flow([...])` flattens `Flow`
  #      instances passed as steps, so an inner transactional `Flow`
  #      *loses* its transaction wrapper when nested. The class-based
  #      forms keep their transaction (classes are not flattened).
  class Micro::Cases::Flow::TransactionCompositionMatrixTest < Minitest::Test
    include TransactionSteps

    STEPS = [A, B, C, D, E].freeze

    def setup
      Widget.delete_all
    end

    def assert_full_chain_accumulation(result)
      assert_kind_of(Micro::Case::Result, result)
      assert_predicate(result, :success?)

      data = result.data
      assert_equal(%w[A B C D E], data[:log])
      assert_equal(5, data[:counter])
      assert_equal('E', data[:e_marker])

      %i[log counter a_marker b_marker c_marker d_marker].each do |key|
        assert_includes(result.accessible_attributes, key)
      end
    end

    # -----------------------------------------------------------------------
    # 1. Behavioral transparency — TX wrappers behave like regular flows
    #    for the user-visible result. Run every wrapper standalone with the
    #    full 5-step chain; assertions are identical to the non-tx matrix.
    # -----------------------------------------------------------------------
    ALL_WRAPPERS.each_key do |wrapper_name|
      define_method("test_level_1_#{wrapper_name}_accumulates_state_and_commits") do
        flow = ALL_WRAPPERS.fetch(wrapper_name).call(STEPS)

        result = flow.call(INPUT)

        assert_full_chain_accumulation(result)
        # Every successful step persisted exactly one Widget row.
        assert_equal(%w[A B C D E], Widget.order(:id).pluck(:name))
      end
    end

    # -----------------------------------------------------------------------
    # 2. Two-level transparency: every wrapper inside every wrapper,
    #    inner = [A, B], outer = [<inner>, C, D, E]. The result is always
    #    A -> B -> C -> D -> E regardless of which level holds a tx.
    # -----------------------------------------------------------------------
    ALL_WRAPPERS.each_key do |outer_name|
      ALL_WRAPPERS.each_key do |inner_name|
        define_method("test_level_2_outer_#{outer_name}_inner_#{inner_name}") do
          inner = ALL_WRAPPERS.fetch(inner_name).call([A, B])
          outer = ALL_WRAPPERS.fetch(outer_name).call([inner, C, D, E])

          result = outer.call(INPUT)

          assert_full_chain_accumulation(result)
          assert_equal(%w[A B C D E], Widget.order(:id).pluck(:name))
        end
      end
    end

    # -----------------------------------------------------------------------
    # 3. Transitions are unaffected by the tx kwarg — every leaf step
    #    produces exactly one transition entry in the correct order, even
    #    when nested under any combination of tx / non-tx wrappers.
    #    (Only runs when transitions are enabled in the current bundle.)
    # -----------------------------------------------------------------------
    if ::Micro::Case::Result.transitions_enabled?
      ALL_WRAPPERS.each_key do |outer_name|
        ALL_WRAPPERS.each_key do |inner_name|
          define_method("test_transitions_unaffected_outer_#{outer_name}_inner_#{inner_name}") do
            inner = ALL_WRAPPERS.fetch(inner_name).call([A, B])
            outer = ALL_WRAPPERS.fetch(outer_name).call([inner, C, D, E])

            result = outer.call(INPUT)

            transition_classes = result.transitions.map { |t| t[:use_case][:class] }
            assert_equal([A, B, C, D, E], transition_classes)
          end
        end
      end
    end

    # -----------------------------------------------------------------------
    # 4. Rollback on failure at the outermost transactional level.
    #    [A, B, Fail, C] inside each tx wrapper: all 3 prior widget rows
    #    (A, B, Fail) must be rolled back.
    # -----------------------------------------------------------------------
    TX_WRAPPER_NAMES.each do |tx_wrapper|
      define_method("test_rollback_on_failure_in_#{tx_wrapper}") do
        flow = ALL_WRAPPERS.fetch(tx_wrapper).call([A, B, Fail, C])

        result = flow.call(INPUT)

        assert_predicate(result, :failure?)
        assert_equal(:step_failed, result.type)
        assert_equal(0, Widget.count, "expected rollback for #{tx_wrapper}, found #{Widget.pluck(:name).inspect}")
      end
    end

    # -----------------------------------------------------------------------
    # 5. Rollback on exception via SAFE transactional wrappers. Plain
    #    (non-safe) tx wrappers re-raise — exceptions never reach the
    #    flow's `result.failure?` check and AR aborts the transaction on
    #    the raise itself (no rows persist either way).
    # -----------------------------------------------------------------------
    %i[cases_safe_flow_tx safe_class_flow_tx].each do |safe_tx|
      define_method("test_safe_#{safe_tx}_rolls_back_on_exception") do
        flow = ALL_WRAPPERS.fetch(safe_tx).call([A, Boom, B])

        result = flow.call(INPUT)

        assert_predicate(result, :failure?)
        assert_equal(:exception, result.type)
        assert_kind_of(BoomError, result.data[:exception])
        assert_equal(0, Widget.count)
      end
    end

    # -----------------------------------------------------------------------
    # 6. Plain (non-safe) tx wrappers — the exception re-raises out of
    #    the flow, but the transaction still rolls back.
    # -----------------------------------------------------------------------
    %i[cases_flow_tx class_flow_tx].each do |plain_tx|
      define_method("test_plain_#{plain_tx}_rolls_back_when_step_raises") do
        flow = ALL_WRAPPERS.fetch(plain_tx).call([A, Boom, B])

        assert_raises(BoomError) { flow.call(INPUT) }
        assert_equal(0, Widget.count)
      end
    end

    # -----------------------------------------------------------------------
    # 7. Inner tx flow wrapped in a class. The outer flow is non-tx, so
    #    if the OUTER fails AFTER a successful inner tx, the inner's
    #    writes are already committed and survive.
    # -----------------------------------------------------------------------
    def test_inner_tx_class_commits_when_outer_fails_later
      inner_class = Class.new(Micro::Case) { flow(transaction: true, steps: [A, B]) }
      outer = Micro::Cases.flow([inner_class, Fail])

      result = outer.call(INPUT)

      assert_predicate(result, :failure?)
      # Inner tx already committed before Fail ran outside any tx.
      assert_equal(%w[A B Fail], Widget.order(:id).pluck(:name))
    end

    # -----------------------------------------------------------------------
    # 8. Inner tx flow as a class, OUTER also tx. AR's nested transactions
    #    join the outer one (no `requires_new: true`), so a failure
    #    anywhere rolls back the WHOLE chain — including writes performed
    #    by the inner "transaction".
    # -----------------------------------------------------------------------
    def test_outer_tx_rolls_back_inner_tx_writes_too
      inner_class = Class.new(Micro::Case) { flow(transaction: true, steps: [A, B]) }
      outer = Micro::Cases.flow(transaction: true, steps: [inner_class, Fail])

      result = outer.call(INPUT)

      assert_predicate(result, :failure?)
      assert_equal(0, Widget.count)
    end

    # -----------------------------------------------------------------------
    # 9. Flow-INSTANCE flattening: passing a tx Flow instance as a step
    #    flattens it into its leaf steps and LOSES the transaction.
    #    This is documented existing flatten behavior; the test pins
    #    it down for future regression coverage.
    # -----------------------------------------------------------------------
    def test_inner_tx_flow_instance_is_flattened_and_loses_its_transaction
      inner_flow = Micro::Cases.flow(transaction: true, steps: [A, B])
      outer = Micro::Cases.flow([inner_flow, Fail])

      result = outer.call(INPUT)

      assert_predicate(result, :failure?)
      # Inner was flattened, so its tx never engaged; outer is non-tx;
      # every widget row persists.
      assert_equal(%w[A B Fail], Widget.order(:id).pluck(:name))
    end

    # -----------------------------------------------------------------------
    # 10. Failure deep inside a nested tx class rolls back regardless of
    #     which TX wrapper is at which level.
    # -----------------------------------------------------------------------
    TX_WRAPPER_NAMES.each do |outer_tx|
      TX_WRAPPER_NAMES.each do |inner_tx|
        define_method("test_deep_rollback_outer_#{outer_tx}_inner_#{inner_tx}") do
          # Build the inner as a CLASS so it isn't flattened.
          inner_class = Class.new(Micro::Case) {
            flow(transaction: true, steps: [TransactionSteps::A, TransactionSteps::Fail])
          }
          outer = ALL_WRAPPERS.fetch(outer_tx).call([inner_class, B, C])

          result = outer.call(INPUT)

          assert_predicate(result, :failure?)
          assert_equal(:step_failed, result.type)
          assert_equal(0, Widget.count, "expected rollback for outer=#{outer_tx} inner=#{inner_tx}, got #{Widget.pluck(:name).inspect}")
        end
      end
    end

    # -----------------------------------------------------------------------
    # 11. Behavioral parity: run the SAME chain under a non-tx wrapper
    #     and its tx twin; the result.data must be equal field-by-field.
    # -----------------------------------------------------------------------
    NON_TX_WRAPPERS.each_key do |non_tx_name|
      tx_name = :"#{non_tx_name}_tx"
      next unless TX_WRAPPERS.key?(tx_name)

      define_method("test_tx_and_non_tx_result_data_match_for_#{non_tx_name}") do
        non_tx_result = NON_TX_WRAPPERS.fetch(non_tx_name).call(STEPS).call(INPUT)
        Widget.delete_all
        tx_result = TX_WRAPPERS.fetch(tx_name).call(STEPS).call(INPUT)

        assert_equal(non_tx_result.data, tx_result.data)
        assert_equal(non_tx_result.type, tx_result.type)
        assert_equal(non_tx_result.success?, tx_result.success?)
        assert_equal(
          non_tx_result.accessible_attributes.sort,
          tx_result.accessible_attributes.sort
        )
      end
    end

    # -----------------------------------------------------------------------
    # 12. Result#then across a tx boundary — chaining a use case onto the
    #     result of a tx flow keeps accumulating state and transitions.
    # -----------------------------------------------------------------------
    if ::Micro::Case::Result.transitions_enabled?
      def test_then_after_tx_flow_keeps_accumulating
        flow = Micro::Cases.flow(transaction: true, steps: [A, B])

        result = flow.call(INPUT).then(C).then(D).then(E)

        assert_full_chain_accumulation(result)
        transition_classes = result.transitions.map { |t| t[:use_case][:class] }
        assert_equal([A, B, C, D, E], transition_classes)
      end
    end
  end
end
