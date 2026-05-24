require 'test_helper'
require 'support/composition_steps'

# Exhaustively exercises every supported way of composing flows in u-case
# and verifies that state is always accumulated across the entire chain,
# regardless of how deep or mixed the composition is.
#
# Composition forms (wrappers) exercised:
#
#   * Micro::Cases.flow([...])
#   * Micro::Cases.safe_flow([...])
#   * class < Micro::Case;       flow(...) end
#   * class < Micro::Case::Safe; flow(...) end
#
# Each test starts from {log: [], counter: 0} and expects the canonical
# A -> B -> C -> D -> E chain to leave behind:
#
#   * log     == ["A","B","C","D","E"]
#   * counter == 5
#   * E's marker key in result.data
#   * every prior step's marker key in result.accessible_attributes
class Micro::Cases::Flow::CompositionMatrixTest < Minitest::Test
  include CompositionSteps

  STEPS = [A, B, C, D, E].freeze

  def assert_full_chain_accumulation(result)
    assert_kind_of(Micro::Case::Result, result)
    assert_predicate(result, :success?)

    data = result.data
    assert_equal(%w[A B C D E], data[:log], "log not accumulated across chain")
    assert_equal(5, data[:counter], "counter not accumulated across chain")
    assert_equal('E', data[:e_marker])

    # accessible_attributes tracks attributes that were passed *into* a use
    # case. The final step's brand-new output keys are reachable through
    # result.data; the earlier markers must be available on every step that
    # follows the one which produced them.
    %i[log counter a_marker b_marker c_marker d_marker].each do |key|
      assert_includes(
        result.accessible_attributes, key,
        "expected :#{key} to be in accessible_attributes after the full chain"
      )
    end
  end

  # ---------------------------------------------------------------------------
  # Level 1: each wrapper used standalone with the full 5-step chain.
  # ---------------------------------------------------------------------------
  WRAPPERS.each_key do |wrapper_name|
    define_method("test_level_1_#{wrapper_name}_accumulates_state") do
      flow = WRAPPERS.fetch(wrapper_name).call(STEPS)

      result = flow.call(INPUT)

      assert_full_chain_accumulation(result)
    end
  end

  # ---------------------------------------------------------------------------
  # Level 2 pair matrix: every wrapper inside every wrapper, with the inner
  # holding [A, B] and the outer holding [<inner>, C, D, E].
  # ---------------------------------------------------------------------------
  WRAPPERS.each_key do |outer_name|
    WRAPPERS.each_key do |inner_name|
      define_method("test_level_2_outer_#{outer_name}_inner_#{inner_name}") do
        inner = WRAPPERS.fetch(inner_name).call([A, B])
        outer = WRAPPERS.fetch(outer_name).call([inner, C, D, E])

        result = outer.call(INPUT)

        assert_full_chain_accumulation(result)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Full 4-level matrix: 4 wrappers ^ 4 levels = 256 combinations.
  #
  #   L1 wraps [A, B]
  #   L2 wraps [L1, C]
  #   L3 wraps [L2, D]
  #   L4 wraps [L3, E]
  #
  # Every combination must execute A -> B -> C -> D -> E and accumulate state.
  # ---------------------------------------------------------------------------
  WRAPPERS.each_key do |w1|
    WRAPPERS.each_key do |w2|
      WRAPPERS.each_key do |w3|
        WRAPPERS.each_key do |w4|
          method_name = "test_level_4_#{w1}__#{w2}__#{w3}__#{w4}"

          define_method(method_name) do
            l1 = WRAPPERS.fetch(w1).call([A, B])
            l2 = WRAPPERS.fetch(w2).call([l1, C])
            l3 = WRAPPERS.fetch(w3).call([l2, D])
            l4 = WRAPPERS.fetch(w4).call([l3, E])

            result = l4.call(INPUT)

            assert_full_chain_accumulation(result)
          end
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Failure propagation: a failing step short-circuits the chain regardless
  # of where in the nesting it sits.
  # ---------------------------------------------------------------------------
  WRAPPERS.each_key do |wrapper_name|
    define_method("test_failure_short_circuit_in_#{wrapper_name}") do
      flow = WRAPPERS.fetch(wrapper_name).call([A, Fail, B, C])

      result = flow.call(INPUT)

      assert_predicate(result, :failure?)
      assert_equal(:step_failed, result.type)
      assert_equal(%w[A Fail], result.data[:log])
      assert_equal(2, result.data[:counter])
      assert_instance_of(Fail, result.use_case)
    end
  end

  def test_failure_short_circuit_in_deep_nesting
    WRAPPERS.each_key do |w1|
      WRAPPERS.each_key do |w4|
        l1 = WRAPPERS.fetch(w1).call([A, Fail])
        l2 = WRAPPERS.fetch(w1).call([l1, B])
        l3 = WRAPPERS.fetch(w4).call([l2, C])
        l4 = WRAPPERS.fetch(w4).call([l3, D])

        result = l4.call(INPUT)

        assert_predicate(result, :failure?, "expected failure for #{w1}/#{w4}")
        assert_equal(:step_failed, result.type)
        assert_instance_of(Fail, result.use_case)
        assert_equal(%w[A Fail], result.data[:log])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Safe wrappers must rescue exceptions raised by a leaf step, anywhere in
  # the chain, and surface them as :exception failures.
  # ---------------------------------------------------------------------------
  %i[cases_safe_flow safe_class_flow].each do |safe_wrapper|
    define_method("test_safe_wrapper_#{safe_wrapper}_rescues_exception_at_level_1") do
      flow = WRAPPERS.fetch(safe_wrapper).call([A, Boom, B])

      result = flow.call(INPUT)

      assert_predicate(result, :failure?)
      assert_equal(:exception, result.type)
      assert_kind_of(BoomError, result.data[:exception])
    end
  end

  def test_safe_wrapper_rescues_exception_in_deeply_nested_chain
    %i[cases_safe_flow safe_class_flow].each do |outer_safe|
      %i[cases_safe_flow safe_class_flow].each do |inner_safe|
        inner = WRAPPERS.fetch(inner_safe).call([A, Boom])
        outer = WRAPPERS.fetch(outer_safe).call([inner, B, C])

        result = outer.call(INPUT)

        assert_predicate(result, :failure?, "expected failure for #{outer_safe}/#{inner_safe}")
        assert_equal(:exception, result.type)
        assert_kind_of(BoomError, result.data[:exception])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Transitions: every successful step in the chain must produce exactly one
  # transition entry in the final result, even when the chain spans 4 levels
  # of mixed wrappers.
  # ---------------------------------------------------------------------------
  if ::Micro::Case::Result.transitions_enabled?
    WRAPPERS.each_key do |w1|
      WRAPPERS.each_key do |w2|
        WRAPPERS.each_key do |w3|
          WRAPPERS.each_key do |w4|
            method_name = "test_transitions_count_4_levels_#{w1}__#{w2}__#{w3}__#{w4}"

            define_method(method_name) do
              l1 = WRAPPERS.fetch(w1).call([A, B])
              l2 = WRAPPERS.fetch(w2).call([l1, C])
              l3 = WRAPPERS.fetch(w3).call([l2, D])
              l4 = WRAPPERS.fetch(w4).call([l3, E])

              result = l4.call(INPUT)

              assert_predicate(result, :success?)

              transition_classes = result.transitions.map { |t| t[:use_case][:class] }

              assert_equal(
                [A, B, C, D, E],
                transition_classes,
                "expected one transition per leaf step in #{w1}/#{w2}/#{w3}/#{w4}, got #{transition_classes.inspect}"
              )
            end
          end
        end
      end
    end
  end
end
