require 'test_helper'

class Micro::Service::StrictTest < Minitest::Test
  class Multiply < Micro::Service::Strict
    attributes :a, :b

    def call!
      if a.is_a?(Numeric) && b.is_a?(Numeric)
        Success(a * b)
      else
        Failure(:invalid_data)
      end
    end
  end

  class Double < Micro::Service::Strict
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

  class Foo < Micro::Service::Strict
  end

  def test_template_method
    assert_raises(NotImplementedError) { Micro::Service::Strict.call }
    assert_raises(NotImplementedError) { Micro::Service::Strict.new({}).call }

    assert_raises(NotImplementedError) { Foo.call }
    assert_raises(NotImplementedError) { Foo.new({}).call }
  end

  class LoremIpsum < Micro::Service::Strict
    attributes :text

    def call!
      text
    end
  end

  def test_result_error
    err1 = assert_raises(Micro::Service::Error::UnexpectedResult) { LoremIpsum.call(text: 'lorem ipsum') }
    assert_equal('Micro::Service::StrictTest::LoremIpsum#call! must return an instance of Micro::Service::Result', err1.message)

    err2 = assert_raises(Micro::Service::Error::UnexpectedResult) { LoremIpsum.new(text: 'ipsum indolor').call }
    assert_equal('Micro::Service::StrictTest::LoremIpsum#call! must return an instance of Micro::Service::Result', err2.message)
  end

  def test_keywords_validation
    err1 = assert_raises(ArgumentError) { Multiply.call({}) }
    err2 = assert_raises(ArgumentError) { Multiply.call({a: 1}) }

    assert_equal('missing keywords: :a, :b', err1.message)
    assert_equal('missing keyword: :b', err2.message)

    err3 = assert_raises(ArgumentError) { Double.call({}) }
    assert_equal('missing keyword: :number', err3.message)
  end

  class Divide < Micro::Service::Strict
    attributes :a, :b

    def call!
      return Success(a / b) if a.is_a?(Integer) && b.is_a?(Integer)
      Failure(:not_an_integer)
    rescue => e
      Failure(e)
    end
  end

  def test_the_exception_result_type
    result = Divide.call(a: 2, b: 0)
    counter = 0

    refute(result.success?)
    assert_kind_of(ZeroDivisionError, result.value)

    result.on_failure(:error) { counter += 1 } # will be avoided
    result.on_failure(:exception) { counter -= 1 }
    assert_equal(-1, counter)
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
end
