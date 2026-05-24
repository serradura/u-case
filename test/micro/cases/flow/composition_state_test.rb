require 'test_helper'
require 'support/composition_steps'

# Explicit, transition-by-transition verification that the accumulated state
# (log, counter, and accessible_attributes) is propagated correctly through
# every nesting level of every composition form, including the dependency
# injection step shape ([UseCase, defaults_hash]) and self-referential inner
# flows.
class Micro::Cases::Flow::CompositionStateTest < Minitest::Test
  include CompositionSteps

  def deepest_4_level_flow
    # All four wrappers combined in one chain, each level adding one step on
    # top of the previous. Equivalent runtime chain: A -> B -> C -> D -> E.
    l1 = WRAPPERS.fetch(:cases_flow).call([A, B])
    l2 = WRAPPERS.fetch(:class_flow).call([l1, C])
    l3 = WRAPPERS.fetch(:cases_safe_flow).call([l2, D])
    WRAPPERS.fetch(:safe_class_flow).call([l3, E])
  end

  def test_state_is_visible_to_every_step_in_a_4_level_mixed_chain
    result = deepest_4_level_flow.call(INPUT)

    assert_predicate(result, :success?)
    assert_equal(%w[A B C D E], result.data[:log])
    assert_equal(5, result.data[:counter])

    return unless ::Micro::Case::Result.transitions_enabled?

    transitions = result.transitions

    assert_equal([A, B, C, D, E], transitions.map { |t| t[:use_case][:class] })

    # Each step's input must include every marker produced by previous steps.
    expected_markers_in_input = {
      A => [],
      B => [:a_marker],
      C => [:a_marker, :b_marker],
      D => [:a_marker, :b_marker, :c_marker],
      E => [:a_marker, :b_marker, :c_marker, :d_marker]
    }

    transitions.each do |transition|
      step_class = transition[:use_case][:class]
      input_keys = transition[:use_case][:attributes].keys

      expected_markers_in_input.fetch(step_class).each do |marker|
        assert_includes(
          input_keys, marker,
          "#{step_class} did not receive #{marker.inspect} as input"
        )
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Dependency injection via [UseCase, defaults_hash] step shape.
  # ---------------------------------------------------------------------------
  class Increment < Micro::Case
    attributes :log, :counter, :by

    def call!
      Success result: {
        log: log + ["+#{by}"],
        counter: counter + by
      }
    end
  end

  def test_dependency_injection_step_shape_in_a_nested_flow
    inner = Micro::Cases.flow([
      A,
      [Increment, by: 10]
    ])

    outer = Micro::Cases.flow([
      inner,
      [Increment, by: 5],
      B
    ])

    result = outer.call(INPUT)

    assert_predicate(result, :success?)
    assert_equal(['A', '+10', '+5', 'B'], result.data[:log])
    assert_equal(17, result.data[:counter]) # 1 (A) + 10 + 5 + 1 (B)
  end

  # ---------------------------------------------------------------------------
  # Self-referential inner flow: a use case that includes itself as a step.
  # Both `self` and `self.call!` should produce equivalent inner Self steps.
  # ---------------------------------------------------------------------------
  class SelfReferentialViaSelf < Micro::Case
    flow CompositionSteps::A, self, CompositionSteps::B

    attributes :log, :counter, :a_marker

    def call!
      Success result: {
        log: log + ['Self'],
        counter: counter + 100,
        a_marker: a_marker
      }
    end
  end

  class SelfReferentialViaSelfCallBang < Micro::Case
    flow CompositionSteps::A, self.call!, CompositionSteps::B

    attributes :log, :counter, :a_marker

    def call!
      Success result: {
        log: log + ['SelfBang'],
        counter: counter + 100,
        a_marker: a_marker
      }
    end
  end

  def test_self_referential_inner_flow_via_self_accumulates_state
    result = SelfReferentialViaSelf.call(**INPUT)

    assert_predicate(result, :success?)
    assert_equal(['A', 'Self', 'B'], result.data[:log])
    assert_equal(102, result.data[:counter]) # 1 (A) + 100 (Self) + 1 (B)

    return unless ::Micro::Case::Result.transitions_enabled?

    classes = result.transitions.map { |t| t[:use_case][:class] }
    assert_equal([A, SelfReferentialViaSelf::Self, B], classes)
  end

  def test_self_referential_inner_flow_via_self_call_bang_accumulates_state
    result = SelfReferentialViaSelfCallBang.call(**INPUT)

    assert_predicate(result, :success?)
    assert_equal(['A', 'SelfBang', 'B'], result.data[:log])
    assert_equal(102, result.data[:counter])

    return unless ::Micro::Case::Result.transitions_enabled?

    classes = result.transitions.map { |t| t[:use_case][:class] }
    assert_equal([A, SelfReferentialViaSelfCallBang::Self, B], classes)
  end

  # Combine a self-referential class with the matrix wrappers to ensure
  # transitions propagate when the self-referential class is itself nested
  # inside outer flows.
  def test_self_referential_class_nested_inside_each_wrapper_preserves_transitions
    WRAPPERS.each do |wrapper_name, wrapper|
      flow = wrapper.call([SelfReferentialViaSelf, C, D])

      result = flow.call(INPUT)

      assert_predicate(result, :success?, "expected success for #{wrapper_name}")
      assert_equal(['A', 'Self', 'B', 'C', 'D'], result.data[:log])

      next unless ::Micro::Case::Result.transitions_enabled?

      classes = result.transitions.map { |t| t[:use_case][:class] }

      assert_equal(
        [A, SelfReferentialViaSelf::Self, B, C, D],
        classes,
        "expected all leaf steps to appear in transitions when nested in #{wrapper_name}"
      )
    end
  end

  # ---------------------------------------------------------------------------
  # Cases.flow flattens a Flow instance passed as a step, but a class with an
  # inner flow is kept opaque. The fix to __call_the_use_case_flow guarantees
  # both shapes accumulate state identically.
  # ---------------------------------------------------------------------------
  def test_flow_instance_step_is_flattened_at_build_time
    inner = Micro::Cases.flow([A, B])
    outer = Micro::Cases.flow([inner, C])

    assert_equal([A, B, C], outer.use_cases)
  end

  def test_class_with_inner_flow_step_is_kept_opaque
    inner_class = WRAPPERS.fetch(:class_flow).call([A, B])
    outer = Micro::Cases.flow([inner_class, C])

    assert_equal([inner_class, C], outer.use_cases)
  end

  def test_both_step_shapes_produce_identical_runtime_behaviour
    inner_flow_instance = Micro::Cases.flow([A, B])
    inner_via_class = WRAPPERS.fetch(:class_flow).call([A, B])

    out_via_instance = Micro::Cases.flow([inner_flow_instance, C, D, E])
    out_via_class    = Micro::Cases.flow([inner_via_class,    C, D, E])

    r1 = out_via_instance.call(INPUT)
    r2 = out_via_class.call(INPUT)

    assert_equal(r1.data, r2.data, "flattened and opaque nesting must produce identical data")

    if ::Micro::Case::Result.transitions_enabled?
      assert_equal(
        r1.transitions.map { |t| t[:use_case][:class] },
        r2.transitions.map { |t| t[:use_case][:class] },
        "flattened and opaque nesting must produce identical transitions"
      )
    end
  end
end
