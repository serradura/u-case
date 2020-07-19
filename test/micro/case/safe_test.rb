require 'test_helper'

class Micro::Case::SafeTest < Minitest::Test
  class Divide < Micro::Case::Safe
    attributes :a, :b

    def call!
      if a.is_a?(Integer) && b.is_a?(Integer)
        Success(result: a / b)
      else
        Failure(:not_an_integer)
      end
    end
  end

  def test_instance_call_method
    result = Divide.new(a: 2, b: 2).call

    assert_success_result(result, value: 1)

    # ---

    result = Divide.new(a: 2.0, b: 2).call

    assert_failure_result(result, value: :not_an_integer, type: :not_an_integer)
  end

  def test_class_call_method
    result = Divide.call(a: 2, b: 2)

    assert_success_result(result, value: 1)

    # ---

    result = Divide.call(a: 2.0, b: 2)

    assert_failure_result(result, value: :not_an_integer, type: :not_an_integer)
  end

  class Foo < Micro::Case::Safe
  end

  def test_template_method
    assert_raises(NotImplementedError) { Micro::Case::Safe.call }
    assert_raises(NotImplementedError) { Micro::Case::Safe.new({}).call }

    assert_raises(NotImplementedError) { Foo.call }
    assert_raises(NotImplementedError) { Foo.new({}).call }
  end

  class LoremIpsum < Micro::Case::Safe
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

  def test_that_exceptions_generate_a_failure
    [
      Divide.new(a: 2, b: 0).call,
      Divide.call(a: 2, b: 0)
    ].each do |result|
      assert_exception_result(result, value: ZeroDivisionError)
    end
  end

  class Divide2ByArgV1 < Micro::Case::Safe
    attribute :arg

    def call!
      Success result: 2 / arg
    rescue => e
      Failure result: e
    end
  end

  class Divide2ByArgV2 < Micro::Case::Safe
    attribute :arg

    def call!
      Success(result: 2 / arg)
    rescue => e
      Failure result: e
    end
  end

  class Divide2ByArgV3 < Micro::Case::Safe
    attribute :arg

    def call!
      Success(result: 2 / arg)
    rescue => e
      Failure :foo, result: e
    end
  end

  class GenerateZeroDivisionError < Micro::Case::Safe
    attribute :arg

    def call!
      Failure(result: arg / 0)
    rescue => e
      Success(result: e)
    end
  end

  def test_the_rescue_of_an_exception_inside_of_a_safe_use_case
    [
      Divide2ByArgV1.call(arg: 0),
      Divide2ByArgV2.call(arg: 0)
    ].each do |result|
      assert_exception_result(result, value: ZeroDivisionError)
    end

    # ---

    result = Divide2ByArgV3.call(arg: 0)

    assert_exception_result(result, value: ZeroDivisionError, type: :foo)

    # ---

    result = GenerateZeroDivisionError.call(arg: 2)
    assert_success_result(result)

    assert_kind_of(ZeroDivisionError, result.value)
  end

  def test_that_when_a_failure_result_is_a_symbol_both_type_and_value_will_be_the_same
    result = Divide.call(a: 2, b: 'a')

    assert_failure_result(result, value: :not_an_integer)
  end

  def test_to_proc
    results = [
      {a: 2, b: 2},
      {a: 4, b: 2},
      {a: 6, b: 2},
      {a: 8, b: 2}
    ].map(&Divide)

    values = results.map(&:value)

    assert_equal([1, 2, 3, 4], values)
  end
end
