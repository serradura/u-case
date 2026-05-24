require 'test_helper'
require 'support/composition_steps'

# Result#then is a first-class way to compose flows in u-case: a use case
# or flow can be chained onto an existing Result at runtime, optionally with
# default attributes. Class.then/Flow.then are class-level convenience that
# desugar to .call.then(...).
#
# This file exhaustively crosses the chaining surface with the four flow
# constructors so that state accumulation across mixed compositions is
# guaranteed even when the chain is built dynamically.
class Micro::Cases::Flow::CompositionChainingTest < Minitest::Test
  include CompositionSteps

  # ---------------------------------------------------------------------------
  # Result#then onto every wrapper-built segment.
  # ---------------------------------------------------------------------------
  WRAPPERS.each_key do |wrapper_name|
    define_method("test_result_then_chains_a_step_onto_#{wrapper_name}") do
      flow = WRAPPERS.fetch(wrapper_name).call([A, B, C, D])

      result = flow.call(INPUT).then(E)

      assert_predicate(result, :success?)
      assert_equal(%w[A B C D E], result.data[:log])
      assert_equal(5, result.data[:counter])
      assert_equal('E', result.data[:e_marker])
    end
  end

  WRAPPERS.each_key do |wrapper_name|
    define_method("test_result_then_chains_a_subflow_onto_#{wrapper_name}") do
      head = WRAPPERS.fetch(wrapper_name).call([A, B])
      tail = WRAPPERS.fetch(wrapper_name).call([C, D, E])

      result = head.call(INPUT).then(tail)

      assert_predicate(result, :success?)
      assert_equal(%w[A B C D E], result.data[:log])
      assert_equal(5, result.data[:counter])
    end
  end

  # ---------------------------------------------------------------------------
  # 4-level composition built exclusively via Result#then.
  # ---------------------------------------------------------------------------
  def test_four_levels_of_composition_via_result_then_only
    result =
      A.call(**INPUT)
        .then(B)
        .then(C)
        .then(D)
        .then(E)

    assert_predicate(result, :success?)
    assert_equal(%w[A B C D E], result.data[:log])
    assert_equal(5, result.data[:counter])
  end

  # ---------------------------------------------------------------------------
  # Mixing wrappers and chaining: build a wrapper-based 2-level flow, then
  # extend it with two more steps using #then to reach 4+ composition levels.
  # ---------------------------------------------------------------------------
  WRAPPERS.each_key do |w1|
    WRAPPERS.each_key do |w2|
      define_method("test_mixed_chain_#{w1}__#{w2}__then__then") do
        inner = WRAPPERS.fetch(w1).call([A, B])
        outer = WRAPPERS.fetch(w2).call([inner, C])

        result = outer.call(INPUT).then(D).then(E)

        assert_predicate(result, :success?)
        assert_equal(%w[A B C D E], result.data[:log])
        assert_equal(5, result.data[:counter])
        %i[a_marker b_marker c_marker d_marker].each do |key|
          assert_includes(result.accessible_attributes, key)
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Class.then / Flow.then class-level chaining. These desugar to
  # `self.call.then(other)`, so the head must be callable with no args. We
  # use a head that exposes default values via the input arity-zero call path
  # by going through the explicit .call(INPUT) when needed.
  # ---------------------------------------------------------------------------
  def test_flow_then_chains_a_step_class_level
    # Cases::Flow#then is the public API the README documents.
    head = Micro::Cases.flow([CompositionInit, A, B])
    chained = head.then(C)

    assert_predicate(chained, :success?)
    assert_equal(%w[A B C], chained.data[:log])
    assert_equal(3, chained.data[:counter])
  end

  # A leaf with default values so it can be invoked through `Class.then`.
  class CompositionInit < Micro::Case
    attribute :log,     default: []
    attribute :counter, default: 0

    def call!
      Success result: { log: log, counter: counter }
    end
  end

  def test_use_case_class_then_chains_a_step
    # Use-case class-level then; head is a Micro::Case with default attrs so
    # that `self.call` works without arguments.
    chained = CompositionInit.then(A).then(B).then(C).then(D).then(E)

    assert_predicate(chained, :success?)
    assert_equal(%w[A B C D E], chained.data[:log])
    assert_equal(5, chained.data[:counter])
  end

  # ---------------------------------------------------------------------------
  # Dependency injection via Result#then(use_case, defaults).
  # ---------------------------------------------------------------------------
  class Tag < Micro::Case::Strict
    attributes :log, :counter, :a_marker, :b_marker, :tag

    def call!
      Success result: {
        log: log + ["tag=#{tag}"],
        counter: counter + 1,
        tag: tag
      }
    end
  end

  WRAPPERS.each_key do |wrapper_name|
    define_method("test_result_then_with_defaults_after_#{wrapper_name}") do
      flow = WRAPPERS.fetch(wrapper_name).call([A, B])

      result = flow.call(INPUT).then(Tag, tag: 'X')

      assert_predicate(result, :success?)
      assert_equal(['A', 'B', 'tag=X'], result.data[:log])
      assert_equal(3, result.data[:counter])
      assert_equal('X', result.data[:tag])
    end
  end

  # ---------------------------------------------------------------------------
  # Failure short-circuits the .then chain.
  # ---------------------------------------------------------------------------
  def test_result_then_short_circuits_on_failure
    result =
      A.call(**INPUT)
        .then(Fail)
        .then(B)   # never reached
        .then(C)   # never reached

    assert_predicate(result, :failure?)
    assert_equal(:step_failed, result.type)
    assert_equal(%w[A Fail], result.data[:log])
    assert_equal(2, result.data[:counter])
    assert_instance_of(Fail, result.use_case)
  end

  # ---------------------------------------------------------------------------
  # Transitions: every step participated in via #then must appear exactly
  # once in result.transitions.
  # ---------------------------------------------------------------------------
  if ::Micro::Case::Result.transitions_enabled?
    def test_result_then_appends_one_transition_per_step
      result =
        A.call(**INPUT)
          .then(B)
          .then(C)
          .then(D)
          .then(E)

      assert_equal(
        [A, B, C, D, E],
        result.transitions.map { |t| t[:use_case][:class] }
      )
    end

    WRAPPERS.each_key do |wrapper_name|
      define_method("test_result_then_with_subflow_built_by_#{wrapper_name}_keeps_one_transition_per_leaf") do
        head = WRAPPERS.fetch(wrapper_name).call([A, B])
        tail = WRAPPERS.fetch(wrapper_name).call([C, D, E])

        result = head.call(INPUT).then(tail)

        transition_classes = result.transitions.map { |t| t[:use_case][:class] }

        assert_equal(
          [A, B, C, D, E],
          transition_classes,
          "expected one transition per leaf step when chaining a #{wrapper_name} subflow"
        )
      end
    end
  end
end
