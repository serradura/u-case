require 'test_helper'

class Micro::Case::Strict::SafeTest < Minitest::Test
  class Multiply < Micro::Case::Strict::Safe
    attributes :a, :b

    def call!
      if a.is_a?(Numeric) && b.is_a?(Numeric)
        Success result: { number: a * b }
      else
        Failure(:invalid_data)
      end
    end
  end

  class Double < Micro::Case::Strict::Safe
    attributes :number

    def call!
      return Multiply.call(a: number, b: number) if number > 0

      Failure result: { message: 'number must be greater than 0' }
    end
  end

  def test_class_call_method
    result = Double.call(number: 2)

    assert_success_result(result, data: { number: 4 })

    result = Double.call(number: 0)

    assert_failure_result(result, type: :error, data: { message: 'number must be greater than 0' })
  end

  class Foo < Micro::Case::Strict::Safe
  end

  def test_template_method
    assert_raises(NotImplementedError) { Micro::Case::Strict::Safe.call }

    assert_raises(NotImplementedError) { Foo.call }
  end

  class LoremIpsum < Micro::Case::Strict::Safe
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
  end

  def test_keywords_validation
    assert_raises_with_message(ArgumentError, 'missing keywords: :a, :b') { Multiply.call({}) }

    assert_raises_with_message(ArgumentError, 'missing keyword: :b') { Multiply.call({a: 1}) }

    assert_raises_with_message(ArgumentError, 'missing keyword: :number') { Double.call(a: 1) }
  end

  class Divide < Micro::Case::Strict::Safe
    attributes :a, :b

    def call!
      if a.is_a?(Integer) && b.is_a?(Integer)
        Success(result: a / b)
      else
        Failure(:not_an_integer)
      end
    end
  end

  def test_that_exceptions_generate_a_failure
    result_2 = Divide.call(a: 2, b: 0)

    assert_exception_result(result_2, data: { exception: ZeroDivisionError })
  end

  def test_to_proc
    results = [
      {a: 1, b: 2},
      {a: 2, b: 2},
      {a: 3, b: 2},
      {a: 4, b: 2}
    ].map(&Multiply)

    values = results.map(&:data)

    assert_equal(
      [{number: 2}, {number: 4}, {number: 6}, {number: 8}],
      values
    )
  end

  def test_inspect
    assert_equal(
      '<Micro::Case::Strict::SafeTest::Multiply (Micro::Case::Strict::Safe) attributes=["a", "b"]>',
      Multiply.inspect
    )
  end
end
