require 'test_helper'

class Micro::Case::Result::ThenTest < Minitest::Test
  def build_result(success:, value:, type:, use_case: nil)
    result = Micro::Case::Result.new
    result.__set__(success, value, type, use_case || Micro::Case.send(:new, {}))
    result
  end

  def failure_result(options = {})
    build_result(**{ type: :error }.merge(options).merge(success: false))
  end

  def success_result(options = {})
    build_result(**{ type: :ok }.merge(options).merge(success: true))
  end

  if RUBY_VERSION < '2.5.0'
    def test_the_not_implemented_error
      result1 = success_result(value: {number: 0})
      result2 = failure_result(value: {number: 1})

      assert_raises(NotImplementedError) { result1.then { 0 } }
      assert_raises(NotImplementedError) { result2.then { 0 } }
    end
  else
    def test_the_method_then_with_a_block
      success = success_result(value: {number: 0})
      success_incr = 0

      then_output1 =
      success.then { |result| result.success? ? success_incr += 1 : 0 }

      refute_instance_of(Micro::Case::Result, then_output1)
      assert_equal(success_incr, then_output1)

      # ---

      failure = failure_result(value: {number: 1})
      failure_incr = 0

      then_output2 =
        failure.then { |result| result.failure? ? failure_incr += 1 : 0 }

      refute_instance_of(Micro::Case::Result, then_output2)
      assert_equal(failure_incr, then_output2)
    end

    def test_the_method_then_without_a_block_or_an_argument
      success = success_result(value: {number: 0})

      assert_instance_of(Enumerator, success.then)

      # ---

      failure = failure_result(value: {number: 1})

      assert_instance_of(Enumerator, failure.then)
    end
  end

  class ConvertTextIntoInteger < Micro::Case
    attribute :text

    def call!
      if Kind::String?(text) && text =~ /\A\d+\z/
        Success result: { number: text.to_i }
      else
        Failure(:text_isnt_a_string_only_with_numbers)
      end
    end
  end

  class Add3 < Micro::Case
    attribute :number

    def call!
      Success result: { number: number + 3 }
    end
  end

  def test_the_output_when_call_the_then_method_with_an_use_case
    result1 = ConvertTextIntoInteger.call(text: '0').then(Add3)

    assert_success_result(result1, value: { number: 3 })

    if ::Micro::Case::Result.transitions_enabled?
      expected_transitions1 = [
        {
          use_case: {
            class: ConvertTextIntoInteger, attributes: { text: '0'}
          },
          success: {
            type: :ok, result: { number: 0 }
          },
          accessible_attributes: [:text]
        },
        {
          use_case: {
            class: Add3, attributes: { number: 0 }
          },
          success: {
            type: :ok, result: { number: 3 }
          },
          accessible_attributes: [:text, :number]
        }
      ]

      result1.transitions.each_with_index do |transition, index|
        assert_equal(expected_transitions1[index], transition)
      end
    else
      assert_equal([], result1.transitions)
    end

    # ---

    result2 = ConvertTextIntoInteger.call(text: 0).then(Add3)

    assert_failure_result(result2, value: { text_isnt_a_string_only_with_numbers: true })

    if ::Micro::Case::Result.transitions_enabled?
      expected_transitions2 = [
        {
          use_case: {
            class: ConvertTextIntoInteger, attributes: { text: 0}
          },
          failure: {
            type: :text_isnt_a_string_only_with_numbers,
            result: { text_isnt_a_string_only_with_numbers: true }
          },
          accessible_attributes: [:text]
        }
      ]

      result2.transitions.each_with_index do |transition, index|
        assert_equal(expected_transitions2[index], transition)
      end
    else
      assert_equal([], result2.transitions)
    end
  end

  def test_the_invalid_invocation_error_when_the_method_then_was_called_without_an_use_case
    result1 = success_result(value: {number: 0})
    result2 = failure_result(value: {number: 1})

    assert_raises_with_message(
      Micro::Case::Error::InvalidInvocationOfTheThenMethod,
      'Invalid invocation of the Micro::Case::Result#then method'
    ) { result1.then(1) }

    assert_raises_with_message(
      Micro::Case::Error::InvalidInvocationOfTheThenMethod,
      'Invalid invocation of the Micro::Case::Result#then method'
    ) { result2.then(1) { 0 } }
  end

  class FooBar < Micro::Case
    attributes :foo, :bar

    def call!
      return Success(:filled_foo_and_bar) if foo && bar

      Failure(:missing_foo_or_bar)
    end
  end

  class Foo < Micro::Case
    attributes :foo

    def call!
      return Success(:filled_foo) if foo

      Failure(:missing_foo)
    end
  end

  class Bar < Micro::Case
    attributes :bar

    def call!
      return Success(:filled_bar) if bar

      Failure(:missing_bar)
    end
  end

  FooAndBar = Micro::Cases.flow([Foo, Bar])

  class FooBarBaz < Micro::Case
    attributes :foo, :bar, :baz

    def call!
      return Success(:filled_foo_and_bar_and_baz) if foo && bar && baz

      Failure(:missing_foo_or_bar_or_baz)
    end
  end

  def test_the_accessibility_of_accumulated_data
    result1 =
      FooBar
        .call(foo: 'foo', bar: 'bar')
        .then(Foo)
        .then(Bar)

    assert_success_result(result1, type: :filled_bar)

    result1_transitions = result1.transitions

    if ::Micro::Case::Result.transitions_enabled?
      [
        {
          use_case: { class: FooBar, attributes: { foo: 'foo', bar: 'bar'} },
          success: { type: :filled_foo_and_bar, result: { filled_foo_and_bar: true } },
          accessible_attributes: [:foo, :bar]
        },
        {
          use_case: { class: Foo, attributes: { foo: 'foo' } },
          success: { type: :filled_foo, result: { filled_foo: true } },
          accessible_attributes: [:foo, :bar, :filled_foo_and_bar]
        },
        {
          use_case: { class: Bar, attributes: { bar: 'bar' }},
          success: { type: :filled_bar, result: { filled_bar: true } },
          accessible_attributes: [:foo, :bar, :filled_foo_and_bar, :filled_foo]
        }
      ].each_with_index do |expected_transition, index|
        assert_equal(expected_transition, result1_transitions[index])
      end
    else
      assert_equal([], result1_transitions)
    end

    # ---

    result2 =
      FooAndBar
        .call(foo: 'foo', bar: 'bar')
        .then(FooBar)
        .then(Bar)

    assert_success_result(result2, type: :filled_bar)

    result2_transitions = result2.transitions

    if ::Micro::Case::Result.transitions_enabled?
      [
        {
          use_case: { class: Foo, attributes: { foo: 'foo' } },
          success: { type: :filled_foo, result: { filled_foo: true } },
          accessible_attributes: [:foo, :bar]
        },
        {
          use_case: { class: Bar, attributes: { bar: 'bar' }},
          success: { type: :filled_bar, result: { filled_bar: true } },
          accessible_attributes: [:foo, :bar, :filled_foo]
        },
        {
          use_case: { class: FooBar, attributes: { foo: 'foo', bar: 'bar'} },
          success: { type: :filled_foo_and_bar, result: { filled_foo_and_bar: true } },
          accessible_attributes: [:foo, :bar, :filled_foo, :filled_bar]
        },
        {
          use_case: { class: Bar, attributes: { bar: 'bar' }},
          success: { type: :filled_bar, result: { filled_bar: true } },
          accessible_attributes: [:foo, :bar, :filled_foo, :filled_bar, :filled_foo_and_bar]
        },
      ].each_with_index do |expected_transition, index|
        assert_equal(expected_transition, result2_transitions[index])
      end
    else
      assert_equal([], result2_transitions)
    end
  end

  def test_the_injection_of_values
    result1 =
      Foo
        .call(foo: 'foo')
        .then(FooBar, bar: 'bar')

    assert_success_result(result1, type: :filled_foo_and_bar)

    result1_transitions = result1.transitions

    if ::Micro::Case::Result.transitions_enabled?
      [
        {
          use_case: { class: Foo, attributes: { foo: 'foo' } },
          success: { type: :filled_foo, result: { filled_foo: true } },
          accessible_attributes: [:foo]
        },
        {
          use_case: { class: FooBar, attributes: { foo: 'foo', bar: 'bar'} },
          success: { type: :filled_foo_and_bar, result: { filled_foo_and_bar: true } },
          accessible_attributes: [:foo, :filled_foo, :bar]
        }
      ].each_with_index do |expected_transition, index|
        assert_equal(expected_transition, result1_transitions[index])
      end
    else
      assert_equal([], result1_transitions)
    end

    # ---

    result2 =
      Bar
        .call(bar: 'bar')
        .then(FooBar, foo: 'foo')

    assert_success_result(result2, type: :filled_foo_and_bar)

    result2_transitions = result2.transitions

    if ::Micro::Case::Result.transitions_enabled?
      [
        {
          use_case: { class: Bar, attributes: { bar: 'bar' }},
          success: { type: :filled_bar, result: { filled_bar: true } },
          accessible_attributes: [:bar]
        },
        {
          use_case: { class: FooBar, attributes: { foo: 'foo', bar: 'bar'} },
          success: { type: :filled_foo_and_bar, result: { filled_foo_and_bar: true } },
          accessible_attributes: [:bar, :filled_bar, :foo]
        }
      ].each_with_index do |expected_transition, index|
        assert_equal(expected_transition, result2_transitions[index])
      end
    else
      assert_equal([], result2_transitions)
    end

    # ---

    result3 =
      FooBar
        .call(foo: 'foo', bar: 'bar')
        .then(FooBarBaz, baz: 'baz')

    assert_success_result(result3, type: :filled_foo_and_bar_and_baz)

    result3_transitions = result3.transitions

    if ::Micro::Case::Result.transitions_enabled?
      [
        {
          use_case: { class: FooBar, attributes: { foo: 'foo', bar: 'bar'} },
          success: { type: :filled_foo_and_bar, result: { filled_foo_and_bar: true } },
          accessible_attributes: [:foo, :bar]
        },
        {
          use_case: { class: FooBarBaz, attributes: { foo: 'foo', bar: 'bar', baz: 'baz'} },
          success: { type: :filled_foo_and_bar_and_baz, result: { filled_foo_and_bar_and_baz: true } },
          accessible_attributes: [:foo, :bar, :filled_foo_and_bar, :baz]
        },
      ].each_with_index do |expected_transition, index|
        assert_equal(expected_transition, result3_transitions[index])
      end
    else
      assert_equal([], result3_transitions)
    end

    # ---

    result4 =
      FooAndBar
        .call(foo: 'foo', bar: 'bar')
        .then(FooBarBaz, baz: 'baz')

    assert_success_result(result4, type: :filled_foo_and_bar_and_baz)

    result4_transitions = result4.transitions

    if ::Micro::Case::Result.transitions_enabled?
      [
        {
          use_case: { class: Foo, attributes: { foo: 'foo' } },
          success: { type: :filled_foo, result: { filled_foo: true } },
          accessible_attributes: [:foo, :bar]
        },
        {
          use_case: { class: Bar, attributes: { bar: 'bar' }},
          success: { type: :filled_bar, result: { filled_bar: true } },
          accessible_attributes: [:foo, :bar, :filled_foo]
        },
        {
          use_case: { class: FooBarBaz, attributes: { foo: 'foo', bar: 'bar', baz: 'baz'} },
          success: { type: :filled_foo_and_bar_and_baz, result: { filled_foo_and_bar_and_baz: true } },
          accessible_attributes: [:foo, :bar, :filled_foo, :filled_bar, :baz]
        },
      ].each_with_index do |expected_transition, index|
        assert_equal(expected_transition, result4_transitions[index])
      end
    else
      assert_equal([], result4_transitions)
    end
  end
end
