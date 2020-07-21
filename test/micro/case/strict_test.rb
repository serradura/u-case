require 'test_helper'

class Micro::Case::StrictTest < Minitest::Test
  class Multiply < Micro::Case::Strict
    attributes :a, :b

    def call!
      if a.is_a?(Numeric) && b.is_a?(Numeric)
        Success result: { number: a * b }
      else
        Failure(:invalid_data)
      end
    end
  end

  class Double < Micro::Case::Strict
    attributes :number

    def call!
      return Multiply.call(a: number, b: number) if number > 0

      Failure result: { message: 'number must be greater than 0' }
    end
  end

  def test_instance_call_method
    result = Multiply.new(a: 2, b: 2).call

    assert_success_result(result, value: { number: 4 })

    result = Multiply.new(a: 1, b: '1').call

    assert_failure_result(result, type: :invalid_data, value: { invalid_data: true })
  end

  def test_class_call_method
    result = Double.call(number: 2)

    assert_success_result(result, value: { number: 4 })

    result = Double.call(number: 0)

    assert_failure_result(result, type: :error, value: { message: 'number must be greater than 0' })
  end

  class Foo < Micro::Case::Strict
  end

  def test_template_method
    assert_raises(NotImplementedError) { Micro::Case::Strict.call }
    assert_raises(NotImplementedError) { Micro::Case::Strict.new({}).call }

    assert_raises(NotImplementedError) { Foo.call }
    assert_raises(NotImplementedError) { Foo.new({}).call }
  end

  class LoremIpsum < Micro::Case::Strict
    attributes :text

    def call!
      text
    end
  end

  def test_result_error
    assert_raises_with_message(
      Micro::Case::Error::UnexpectedResult,
      /LoremIpsum#call! must return an instance of Micro::Case::Result/
    ) { LoremIpsum.call(text: 'lorem ipsum') }

    assert_raises_with_message(
      Micro::Case::Error::UnexpectedResult,
      /LoremIpsum#call! must return an instance of Micro::Case::Result/
    ) { LoremIpsum.new(text: 'ipsum indolor').call }
  end

  def test_keywords_validation
    assert_raises_with_message(ArgumentError, 'missing keyword: :b') { Multiply.call(a: 1) }
    assert_raises_with_message(ArgumentError, 'missing keywords: :a, :b') { Multiply.call({}) }
    assert_raises_with_message(ArgumentError, 'missing keyword: :number') { Double.call({}) }
  end

  class Divide < Micro::Case::Strict
    attributes :a, :b

    def call!
      if a.is_a?(Integer) && b.is_a?(Integer)
        Success result: { number: a / b }
      else
        Failure(:not_an_integer)
      end
    rescue => e
      Failure result: e
    end
  end

  def test_the_exception_result_type
    result = Divide.call(a: 2, b: 0)

    assert_exception_result(result, value: { exception: ZeroDivisionError })
  end

  def test_that_when_a_failure_result_is_a_symbol_both_type_and_value_will_be_the_same
    result = Divide.call(a: 2, b: 'a')

    assert_failure_result(result, type: :not_an_integer, value: { not_an_integer: true })
  end

  def test_to_proc
    results = [
      {a: 1, b: 2},
      {a: 2, b: 2},
      {a: 3, b: 2},
      {a: 4, b: 2}
    ].map(&Multiply)

    values = results.map(&:value)

    assert_equal(
      [{number: 2}, {number: 4}, {number: 6}, {number: 8}],
      values
    )
  end
end
