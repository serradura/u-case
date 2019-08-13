require 'test_helper'

class Micro::Service::BaseTest < Minitest::Test
  class Multiply < Micro::Service::Base
    attributes :a, :b

    def call!
      if a.is_a?(Numeric) && b.is_a?(Numeric)
        Success(a * b)
      else
        Failure(:invalid_data)
      end
    end
  end

  class Double < Micro::Service::Base
    attributes :number

    def call!
      return Failure { 'number must be greater than 0' } if number <= 0

      Multiply.call(a: number, b: number)
    end
  end

  def test_the_initializer_data_validation
    [nil, 1, true, '', []].each do |arg|
      err = assert_raises(ArgumentError) { Multiply.new(arg) }
      assert_equal('argument must be a Hash', err.message)
    end
  end

  def test_the_instance_call_method
    calculation = Multiply.new(a: 2, b: 2).call

    assert(calculation.success?)
    assert_equal(4, calculation.value)
    assert_kind_of(Micro::Service::Result, calculation)

    result = Multiply.new(a: 1, b: '1').call

    assert(result.failure?)
    assert_equal(:invalid_data, result.value)
    assert_kind_of(Micro::Service::Result, result)
  end

  def test_the_class_call_method
    calculation = Double.call(number: 2)

    assert(calculation.success?)
    assert_equal(4, calculation.value)
    assert_kind_of(Micro::Service::Result, calculation)

    result = Double.call(number: 0)

    assert(result.failure?)
    assert_equal('number must be greater than 0', result.value)
    assert_kind_of(Micro::Service::Result, result)
  end

  def test_the_data_validation_error_when_calling_the_call_class_method
    [nil, 1, true, '', []].each do |arg|
      err = assert_raises(ArgumentError) { Multiply.call(arg) }
      assert_equal('argument must be a Hash', err.message)
    end
  end

  class Foo < Micro::Service::Base
  end

  def test_the_template_method
    assert_raises(NotImplementedError) { Foo.call }

    assert_raises(NotImplementedError) { Foo.new({}).call }
  end

  class LoremIpsum < Micro::Service::Base
    attributes :text

    def call!
      text
    end
  end

  def test_the_result_error
    err1 = assert_raises(TypeError) { LoremIpsum.call(text: 'lorem ipsum') }
    assert_equal('Micro::Service::BaseTest::LoremIpsum#call! must return a Micro::Service::Result instance', err1.message)

    err2 = assert_raises(TypeError) { LoremIpsum.new(text: 'ipsum indolor').call }
    assert_equal('Micro::Service::BaseTest::LoremIpsum#call! must return a Micro::Service::Result instance', err2.message)
  end
end
