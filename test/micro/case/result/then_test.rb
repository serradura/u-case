require 'test_helper'

class Micro::Case::Result::ThenTest < Minitest::Test
  def build_result(success:, value:, type:, use_case: nil)
    result = Micro::Case::Result.new
    result.__set__(success, value, type, use_case || Micro::Case.new({}))
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
      result1 = success_result(value: 0)
      result2 = failure_result(value: 1)

      assert_raises(NotImplementedError) { result1.then { 0 } }
      assert_raises(NotImplementedError) { result2.then { 0 } }

      assert_raises(Micro::Case::Error::InvalidInvocationOfTheThenMethod) { result1.then(1) { 0 } }
      assert_raises(Micro::Case::Error::InvalidInvocationOfTheThenMethod) { result2.then(1) { 0 } }
    end
  else
    def test_the_not_implemented_error
      result1 = success_result(value: 0)
      result2 = failure_result(value: 1)

      assert_raises(Micro::Case::Error::InvalidInvocationOfTheThenMethod) { result1.then(1) { 0 } }
      assert_raises(Micro::Case::Error::InvalidInvocationOfTheThenMethod) { result2.then(1) { 0 } }
    end

    def test_the_method_then_with_a_block
      result1 = success_result(value: 0)
      result2 = failure_result(value: 1)

      result1.then { |result| assert_equal(result1, result) }
      result2.then { |result| assert_equal(result2, result) }
    end

    def test_the_method_then_without_a_block_or_an_argument
      result1 = success_result(value: 0)
      result2 = failure_result(value: 1)

      assert_instance_of(Enumerator, result1.then)
      assert_instance_of(Enumerator, result2.then)
    end
  end

  class ConvertTextIntoInteger < Micro::Case
    attribute :text

    def call!
      if Kind.of.String?(text) && text =~ /\A\d+\z/
        Success { { number: text.to_i } }
      else
        Failure(:text_isnt_a_string_only_with_numbers)
      end
    end
  end

  class Add3 < Micro::Case
    attribute :number

    def call!
      Success { { number: number + 3 } }
    end
  end

  def test_the_output_when_call_the_then_method_with_an_use_case
    result1 = ConvertTextIntoInteger.call(text: '0').then(Add3)

    assert_success_result(result1, value: { number: 3 })

    result1.transitions.tap do |result_transitions|
      assert_equal(2, result_transitions.size)

      # --------------
      # transitions[0]
      # --------------
      first_transition = result_transitions[0]

      # transitions[0][:use_case]
      first_transition_use_case = first_transition[:use_case]

      # transitions[0][:use_case][:class]
      assert_equal(Micro::Case::Result::ThenTest::ConvertTextIntoInteger, first_transition_use_case[:class])

      # transitions[0][:use_case][:attributes]
      assert_equal([:text], first_transition_use_case[:attributes].keys)

      assert_equal('0', first_transition_use_case[:attributes][:text])

      # transitions[0][:success]
      assert(first_transition.include?(:success))

      first_transition_result = first_transition[:success]

      # transitions[0][:success][:type]
      assert_equal(:ok, first_transition_result[:type])

      # transitions[0][:success][:value]
      assert_equal([:number], first_transition_result[:value].keys)

      assert_equal(0, first_transition_result[:value][:number])

      # transitions[0][:accessible_attributes]
      assert_equal([:text], first_transition[:accessible_attributes])

      # --------------
      # transitions[1]
      # --------------

      second_transition = result_transitions[1]

      # transitions[1][:use_case]

      second_transition_use_case = second_transition[:use_case]

      # transitions[1][:use_case][:class]
      assert_equal(Micro::Case::Result::ThenTest::Add3, second_transition_use_case[:class])

      # transitions[1][:use_case][:attributes]
      assert_equal([:number], second_transition_use_case[:attributes].keys)

      assert_equal(0, second_transition_use_case[:attributes][:number])

      # transitions[1][:success]
      assert(second_transition.include?(:success))

      second_transition_result = second_transition[:success]

      # transitions[1][:success][:type]
      assert_equal(:ok, second_transition_result[:type])

      # transitions[1][:success][:value]
      assert_equal([:number], second_transition_result[:value].keys)

      assert_equal(3, second_transition_result[:value][:number])

      # transitions[1][:accessible_attributes]
      assert_equal([:text, :number], second_transition[:accessible_attributes])
    end

    # ---

    result2 = ConvertTextIntoInteger.call(text: 0).then(Add3)

    assert_failure_result(result2, value: :text_isnt_a_string_only_with_numbers)

    result2.transitions.tap do |result_transitions|
      assert_equal(1, result_transitions.size)

      # --------------
      # transitions[0]
      # --------------
      first_transition = result_transitions[0]

      # transitions[0][:use_case]
      first_transition_use_case = first_transition[:use_case]

      # transitions[0][:use_case][:class]
      assert_equal(Micro::Case::Result::ThenTest::ConvertTextIntoInteger, first_transition_use_case[:class])

      # transitions[0][:use_case][:attributes]
      assert_equal([:text], first_transition_use_case[:attributes].keys)

      assert_equal(0, first_transition_use_case[:attributes][:text])

      # transitions[0][:success]
      assert(first_transition.include?(:failure))

      first_transition_result = first_transition[:failure]

      # transitions[0][:success][:type]
      assert_equal(:text_isnt_a_string_only_with_numbers, first_transition_result[:type])

      # transitions[0][:success][:value]

      assert_equal(:text_isnt_a_string_only_with_numbers, first_transition_result[:value])

      # transitions[0][:accessible_attributes]
      assert_equal([:text], first_transition[:accessible_attributes])
    end
  end

  def test_the_not_implemented_error_when_call_the_method_then_without_an_use_case
    result1 = success_result(value: 0)
    result2 = failure_result(value: 1)

    assert_raises(Micro::Case::Error::InvalidInvocationOfTheThenMethod) { result1.then(1) }
    assert_raises(Micro::Case::Error::InvalidInvocationOfTheThenMethod) { result2.then(1) }
  end

  class FooBar < Micro::Case
    attributes :foo, :bar

    def call!
      return Success(filled_foo_and_bar: true) if foo && bar

      Failure(:missing_foo_or_bar)
    end
  end

  class Foo < Micro::Case
    attributes :foo

    def call!
      return Success(filled_foo: true) if foo

      Failure(:missing_foo)
    end
  end

  class Bar < Micro::Case
    attributes :bar

    def call!
      return Success(filled_bar: true) if bar

      Failure(:missing_bar)
    end
  end

  FooAndBar = Micro::Case::Flow([Foo, Bar])

  class FooBarBaz < Micro::Case
    attributes :foo, :bar, :baz

    def call!
      return Success(filled_foo_and_bar_and_baz: true) if foo && bar && baz

      Failure(:missing_foo_or_bar_or_baz)
    end
  end

  def test_the_accessibility_of_accumulated_data
    result1 =
      FooBar
        .call(foo: 'foo', bar: 'bar')
        .then(Foo)
        .then(Bar)

    assert_success_result(result1)

    result1_transitions = result1.transitions

    [
      {
        use_case: { class: FooBar, attributes: { foo: 'foo', bar: 'bar'} },
        success: { type: :ok, value: { filled_foo_and_bar: true } },
        accessible_attributes: [:foo, :bar]
      },
      {
        use_case: { class: Foo, attributes: { foo: 'foo' } },
        success: { type: :ok, value: { filled_foo: true } },
        accessible_attributes: [:foo, :bar, :filled_foo_and_bar]
      },
      {
        use_case: { class: Bar, attributes: { bar: 'bar' }},
        success: { type: :ok, value: { filled_bar: true } },
        accessible_attributes: [:foo, :bar, :filled_foo_and_bar, :filled_foo]
      }
    ].each_with_index do |expected_transition, index|
      assert_equal(expected_transition, result1_transitions[index])
    end

    # ---

    result2 =
      FooAndBar
        .call(foo: 'foo', bar: 'bar')
        .then(FooBar)
        .then(Bar)

    assert_success_result(result2)

    result2_transitions = result2.transitions

    [
      {
        use_case: { class: Foo, attributes: { foo: 'foo' } },
        success: { type: :ok, value: { filled_foo: true } },
        accessible_attributes: [:foo, :bar]
      },
      {
        use_case: { class: Bar, attributes: { bar: 'bar' }},
        success: { type: :ok, value: { filled_bar: true } },
        accessible_attributes: [:foo, :bar, :filled_foo]
      },
      {
        use_case: { class: FooBar, attributes: { foo: 'foo', bar: 'bar'} },
        success: { type: :ok, value: { filled_foo_and_bar: true } },
        accessible_attributes: [:foo, :bar, :filled_foo, :filled_bar]
      },
      {
        use_case: { class: Bar, attributes: { bar: 'bar' }},
        success: { type: :ok, value: { filled_bar: true } },
        accessible_attributes: [:foo, :bar, :filled_foo, :filled_bar, :filled_foo_and_bar]
      },
    ].each_with_index do |expected_transition, index|
      assert_equal(expected_transition, result2_transitions[index])
    end
  end

  def test_the_injection_of_values
    result1 =
      Foo
        .call(foo: 'foo')
        .then(FooBar, bar: 'bar')

    assert_success_result(result1)

    result1_transitions = result1.transitions

    [
      {
        use_case: { class: Foo, attributes: { foo: 'foo' } },
        success: { type: :ok, value: { filled_foo: true } },
        accessible_attributes: [:foo]
      },
      {
        use_case: { class: FooBar, attributes: { foo: 'foo', bar: 'bar'} },
        success: { type: :ok, value: { filled_foo_and_bar: true } },
        accessible_attributes: [:foo, :filled_foo, :bar]
      }
    ].each_with_index do |expected_transition, index|
      assert_equal(expected_transition, result1_transitions[index])
    end

    # ---

    result2 =
      Bar
        .call(bar: 'bar')
        .then(FooBar, foo: 'foo')

    assert_success_result(result2)

    result2_transitions = result2.transitions

    [
      {
        use_case: { class: Bar, attributes: { bar: 'bar' }},
        success: { type: :ok, value: { filled_bar: true } },
        accessible_attributes: [:bar]
      },
      {
        use_case: { class: FooBar, attributes: { foo: 'foo', bar: 'bar'} },
        success: { type: :ok, value: { filled_foo_and_bar: true } },
        accessible_attributes: [:bar, :filled_bar, :foo]
      }
    ].each_with_index do |expected_transition, index|
      assert_equal(expected_transition, result2_transitions[index])
    end

    # ---

    result3 =
      FooBar
        .call(foo: 'foo', bar: 'bar')
        .then(FooBarBaz, baz: 'baz')

    assert_success_result(result3)

    result3_transitions = result3.transitions

    [
      {
        use_case: { class: FooBar, attributes: { foo: 'foo', bar: 'bar'} },
        success: { type: :ok, value: { filled_foo_and_bar: true } },
        accessible_attributes: [:foo, :bar]
      },
      {
        use_case: { class: FooBarBaz, attributes: { foo: 'foo', bar: 'bar', baz: 'baz'} },
        success: { type: :ok, value: { filled_foo_and_bar_and_baz: true } },
        accessible_attributes: [:foo, :bar, :filled_foo_and_bar, :baz]
      },
    ].each_with_index do |expected_transition, index|
      assert_equal(expected_transition, result3_transitions[index])
    end

    # ---

    result4 =
      FooAndBar
        .call(foo: 'foo', bar: 'bar')
        .then(FooBarBaz, baz: 'baz')

    assert_success_result(result4)

    result4_transitions = result4.transitions

    [
      {
        use_case: { class: Foo, attributes: { foo: 'foo' } },
        success: { type: :ok, value: { filled_foo: true } },
        accessible_attributes: [:foo, :bar]
      },
      {
        use_case: { class: Bar, attributes: { bar: 'bar' }},
        success: { type: :ok, value: { filled_bar: true } },
        accessible_attributes: [:foo, :bar, :filled_foo]
      },
      {
        use_case: { class: FooBarBaz, attributes: { foo: 'foo', bar: 'bar', baz: 'baz'} },
        success: { type: :ok, value: { filled_foo_and_bar_and_baz: true } },
        accessible_attributes: [:foo, :bar, :filled_foo, :filled_bar, :baz]
      },
    ].each_with_index do |expected_transition, index|
      assert_equal(expected_transition, result4_transitions[index])
    end
  end
end
