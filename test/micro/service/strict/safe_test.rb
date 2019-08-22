require 'test_helper'

class Micro::Service::Strict::SafeTest < Minitest::Test
  class Multiply < Micro::Service::Strict::Safe
    attributes :a, :b

    def call!
      if a.is_a?(Numeric) && b.is_a?(Numeric)
        Success(a * b)
      else
        Failure(:invalid_data)
      end
    end
  end

  class Double < Micro::Service::Strict::Safe
    attributes :number

    def call!
      return Failure { 'number must be greater than 0' } if number <= 0

      Multiply.call(a: number, b: number)
    end
  end

  def test_instance_call_method
    result = Multiply.new(a: 2, b: 2).call

    assert(result.success?)
    assert_equal(4, result.value)
    assert_kind_of(Micro::Service::Result, result)

    result = Multiply.new(a: 1, b: '1').call

    assert(result.failure?)
    assert_equal(:invalid_data, result.value)
    assert_kind_of(Micro::Service::Result, result)
  end

  def test_class_call_method
    result = Double.call(number: 2)

    assert(result.success?)
    assert_equal(4, result.value)
    assert_kind_of(Micro::Service::Result, result)

    result = Double.call(number: 0)

    assert(result.failure?)
    assert_equal('number must be greater than 0', result.value)
    assert_kind_of(Micro::Service::Result, result)
  end

  class Foo < Micro::Service::Strict::Safe
  end

  def test_template_method
    assert_raises(NotImplementedError) { Micro::Service::Strict::Safe.call }
    assert_raises(NotImplementedError) { Micro::Service::Strict::Safe.new({}).call }

    assert_raises(NotImplementedError) { Foo.call }
    assert_raises(NotImplementedError) { Foo.new({}).call }
  end

  class LoremIpsum < Micro::Service::Strict::Safe
    attributes :text

    def call!
      text
    end
  end

  def test_result_error
    err1 = assert_raises(Micro::Service::Error::UnexpectedResult) { LoremIpsum.call(text: 'lorem ipsum') }
    assert_equal('Micro::Service::Strict::SafeTest::LoremIpsum#call! must return an instance of Micro::Service::Result', err1.message)

    err2 = assert_raises(Micro::Service::Error::UnexpectedResult) { LoremIpsum.new(text: 'ipsum indolor').call }
    assert_equal('Micro::Service::Strict::SafeTest::LoremIpsum#call! must return an instance of Micro::Service::Result', err2.message)
  end

  def test_keywords_validation
    err1 = assert_raises(ArgumentError) { Multiply.call({}) }
    err2 = assert_raises(ArgumentError) { Multiply.call({a: 1}) }

    assert_equal('missing keywords: :a, :b', err1.message)
    assert_equal('missing keyword: :b', err2.message)

    err3 = assert_raises(ArgumentError) { Double.call({}) }
    assert_equal('missing keyword: :number', err3.message)
  end

  class Divide < Micro::Service::Strict::Safe
    attributes :a, :b

    def call!
      if a.is_a?(Integer) && b.is_a?(Integer)
        Success(a / b)
      else
        Failure(:not_an_integer)
      end
    end
  end

  def test_that_exceptions_generate_a_failure
    result_1 = Divide.new(a: 2, b: 0).call

    assert(result_1.failure?)
    assert_instance_of(ZeroDivisionError, result_1.value)
    assert_kind_of(Micro::Service::Result, result_1)

    counter_1 = 0

    result_1
      .on_failure { counter_1 += 1 }
      .on_failure(:exception) { |value| counter_1 += 1 if value.is_a?(ZeroDivisionError) }
      .on_failure(:exception) { |_value, service| counter_1 += 1 if service.is_a?(Divide) }

    assert_equal(3, counter_1)

    # ---

    result_2 = Divide.call(a: 2, b: 0)

    assert(result_2.failure?)
    assert_instance_of(ZeroDivisionError, result_2.value)
    assert_kind_of(Micro::Service::Result, result_2)

    counter_2 = 0

    result_2
      .on_failure { counter_2 += 1 }
      .on_failure(:exception) { |value| counter_2 += 1 if value.is_a?(ZeroDivisionError) }
      .on_failure(:exception) { |_value, service| counter_2 += 1 if service.is_a?(Divide) }

    assert_equal(3, counter_2)
  end
end
