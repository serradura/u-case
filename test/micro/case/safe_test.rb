require 'test_helper'

class Micro::Case::SafeTest < Minitest::Test
  class Divide < Micro::Case::Safe
    attributes :a, :b

    def call!
      if a.is_a?(Integer) && b.is_a?(Integer)
        Success(a / b)
      else
        Failure(:not_an_integer)
      end
    end
  end

  def test_instance_call_method
    result = Divide.new(a: 2, b: 2).call

    assert_success_result(result)
    assert_equal(1, result.value)
    assert_result(result)

    # ---

    result = Divide.new(a: 2.0, b: 2).call

    assert_failure_result(result)
    assert_equal(:not_an_integer, result.value)
    assert_result(result)
  end

  def test_class_call_method
    result = Divide.call(a: 2, b: 2)

    assert_success_result(result)
    assert_equal(1, result.value)
    assert_result(result)

    # ---

    result = Divide.call(a: 2.0, b: 2)

    assert_failure_result(result)
    assert_equal(:not_an_integer, result.value)
    assert_result(result)
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
    err1 = assert_raises(Micro::Case::Error::UnexpectedResult) { LoremIpsum.call(text: 'lorem ipsum') }
    assert_equal('Micro::Case::SafeTest::LoremIpsum#call! must return an instance of Micro::Case::Result', err1.message)

    err2 = assert_raises(Micro::Case::Error::UnexpectedResult) { LoremIpsum.new(text: 'ipsum indolor').call }
    assert_equal('Micro::Case::SafeTest::LoremIpsum#call! must return an instance of Micro::Case::Result', err2.message)
  end

  def test_that_exceptions_generate_a_failure
    [
      Divide.new(a: 2, b: 0).call,
      Divide.call(a: 2, b: 0)
    ].each do |result|
      assert_failure_result(result)
      assert_instance_of(ZeroDivisionError, result.value)
      assert_result(result)

      counter = 0

      result
        .on_failure { counter += 1 }
        .on_failure(:exception) { |value| counter += 1 if value.is_a?(ZeroDivisionError) }
        .on_failure(:exception) { |_value, use_case| counter += 1 if use_case.is_a?(Divide) }

      assert_equal(3, counter)
    end
  end

  class Divide2ByArgV1 < Micro::Case::Safe
    attribute :arg

    def call!
      Success(2 / arg)
    rescue => e
      Failure(e)
    end
  end

  class Divide2ByArgV2 < Micro::Case::Safe
    attribute :arg

    def call!
      Success(2 / arg)
    rescue => e
      Failure { e }
    end
  end

  class Divide2ByArgV3 < Micro::Case::Safe
    attribute :arg

    def call!
      Success(2 / arg)
    rescue => e
      Failure(:foo) { e }
    end
  end

  class GenerateZeroDivisionError < Micro::Case::Safe
    attribute :arg

    def call!
      Failure(arg / 0)
    rescue => e
      Success(e)
    end
  end

  def test_the_rescue_of_an_exception_inside_of_a_safe_use_case
    [
      Divide2ByArgV1.call(arg: 0),
      Divide2ByArgV2.call(arg: 0)
    ].each do |result|
      counter = 0

      refute(result.success?)
      assert_kind_of(ZeroDivisionError, result.value)

      result.on_failure(:exception) { counter += 1 }
      assert_equal(1, counter)
    end

    # ---

    result = Divide2ByArgV3.call(arg: 0)
    counter = 0

    refute(result.success?)
    assert_kind_of(ZeroDivisionError, result.value)

    result.on_failure(:exception) { counter += 1 } # will be avoided
    result.on_failure(:foo) { counter -= 1 }
    assert_equal(-1, counter)

    # ---

    result = GenerateZeroDivisionError.call(arg: 2)
    counter = 0

    assert_success_result(result)
    assert_kind_of(ZeroDivisionError, result.value)

    result.on_success { counter += 1 }
    result.on_failure(:exception) { counter += 1 } # will be avoided
    assert_equal(1, counter)
  end

  def test_that_when_a_failure_result_is_a_symbol_both_type_and_value_will_be_the_same
    result = Divide.call(a: 2, b: 'a')
    counter = 0

    refute(result.success?)
    assert_equal(:not_an_integer, result.value)

    result.on_failure(:error) { counter += 1 } # will be avoided
    result.on_failure(:not_an_integer) { counter -= 1 }
    result.on_failure { counter -= 1 }
    assert_equal(-2, counter)
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
