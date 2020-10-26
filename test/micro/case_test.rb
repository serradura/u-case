require 'test_helper'

class Micro::CaseTest < Minitest::Test
  class Multiply < Micro::Case
    attributes :a, :b

    def call!
      if a.is_a?(Numeric) && b.is_a?(Numeric)
        Success result: { number: a * b }
      else
        Failure :invalid_data, result: { attribute_values: attributes.values }
      end
    end
  end

  class Double < Micro::Case
    attributes :number

    def call!
      return Multiply.call(a: number, b: 2) if number > 0

      Failure result: { message: 'number must be greater than 0' }
    end
  end

  def test_the_case_flow_builder
    assert_same(Micro::Cases::Flow, Double.__flow_builder__)
  end

  def test_the_initializer_data_validation
    [nil, 1, true, '', []].each do |arg|
      assert_raises_with_message(Kind::Error, 'expected to be a kind of Hash') do
        Multiply.call(arg)
      end
    end
  end

  def test_the_class_call_method
    result = Double.call(number: 3)

    assert_success_result(result, value: { number: 6 })

    result = Double.call(number: 0)

    assert_failure_result(result, type: :error, value: { message: 'number must be greater than 0' })
  end

  def test_the_data_validation_error_when_calling_the_call_class_method
    [nil, 1, true, '', []].each do |arg|
      assert_raises_with_message(Kind::Error, 'expected to be a kind of Hash') do
        Multiply.call(arg)
      end
    end
  end

  class Foo < Micro::Case
  end

  def test_the_template_method
    assert_raises(NotImplementedError) { Micro::Case.call }

    assert_raises(NotImplementedError) { Foo.call }
  end

  class LoremIpsum < Micro::Case
    attributes :text

    def call!
      text
    end
  end

  def test_the_result_error
    assert_raises_with_message(
      Micro::Case::Error::UnexpectedResult,
      /LoremIpsum#call! must return an instance of Micro::Case::Result/
    ) { LoremIpsum.call(text: 'lorem ipsum') }
  end

  def test_that_sets_a_result_object_avoiding_the_use_case_to_create_one
    result_instance = Micro::Case::Result.new

    use_case = Multiply.__new__(result_instance, {})

    result = use_case.__call__

    assert_same(result_instance, result)
  end

  def test_the_error_when_trying_to_set_an_invalid_result_object
    use_case = Multiply.__new__(Micro::Case::Result.new, a: 3, b: 2)

    assert_raises_with_message(
      ArgumentError,
      'argument must be an instance of Micro::Case::Result'
    ) { use_case.__set_result__([]) }
  end

  def test_when_already_exists_a_result_and_tries_to_set_a_new_one
    use_case = Multiply.__new__(Micro::Case::Result.new, a: 3, b: 2)

    assert_raises_with_message(ArgumentError, 'result is already defined') do
      use_case.__set_result__(Micro::Case::Result.new)
    end
  end

  class Divide < Micro::Case
    attributes :a, :b

    def call!
      return Success(result: a / b) if a.is_a?(Integer) && b.is_a?(Integer)

      Failure(:not_an_integer)
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

    assert_failure_result(result, value: { not_an_integer: true })
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

  def test_inspect
    assert_equal(
      '<Micro::CaseTest::Multiply (Micro::Case) attributes=["a", "b"]>',
      Multiply.inspect
    )
  end

  class Bomb < Micro::Case
    attributes :defused

    def call!
      Try do
        if defused
          :yay
        else
          raise 'Boooom!'
        end
      end
    end
  end

  def test_try
    result = Bomb.call(defused: true)

    assert_success_result(result, value: { try: :yay }, type: :ok)

    result = Bomb.call(defused: false)

    assert_failure_result(result, type: :exception)
    assert result.value[:try].is_a? RuntimeError
  end

  class BombWithType < Micro::Case
    attributes :defused

    def call!
      Try(:defused) do
        if defused
          :yay
        else
          raise 'Boooom!'
        end
      end
    end
  end
  
  def test_try_with_custom_type
    result = BombWithType.call(defused: true)

    assert_success_result(result, type: :defused, value: { defused: :yay })
    

    result = BombWithType.call(defused: false)

    assert_failure_result(result, type: :defused)
    assert(result.value[:defused].is_a? RuntimeError)
  end

  class Divide2 < Micro::Case
    attributes :a, :b

    def call!
      Try(catch: [ZeroDivisionError, TypeError]) do
        a / b
      end
    end
  end

  def test_try_with_specified_exception
    result = Divide2.call(a: 4 , b: 2)

    assert_success_result(result, value: { try: 2 })

    result = Divide2.call(a: 1 , b: 0)

    assert_failure_result(result)
    assert(result.value[:try].is_a? ZeroDivisionError)

    result = Divide2.call(a: 1 , b: '0')

    assert_failure_result(result)
    assert(result.value[:try].is_a? TypeError)


    assert_raises NoMethodError do
      Divide2.call(a: '1' , b: 0)
    end
  end

  class DivideWithCustomData < Micro::Case
    attributes :a, :b

    def call!
      Try(on: { success: { division: :succeeded }, failure: { division: :failed } }) do
        a / b
      end
    end
  end

  def test_try_with_custom_data
    result = DivideWithCustomData.call(a: 4 , b: 2)

    assert_success_result(result, value: { division: :succeeded })

    result = DivideWithCustomData.call(a: 1 , b: 0)

    assert_failure_result(result, value: { division: :failed })
  end
end
