require 'test_helper'

class Micro::Case::BaseTest < Minitest::Test
  class Multiply < Micro::Case::Base
    attributes :a, :b

    def call!
      if a.is_a?(Numeric) && b.is_a?(Numeric)
        Success(a * b)
      else
        Failure(:invalid_data) { [a, b]}
      end
    end
  end

  class Double < Micro::Case::Base
    attributes :number

    def call!
      return Failure { 'number must be greater than 0' } if number <= 0

      Multiply.call(a: number, b: 2)
    end
  end

  def test_the_initializer_data_validation
    [nil, 1, true, '', []].each do |arg|
      err = assert_raises(ArgumentError) { Multiply.new(arg) }
      assert_equal('argument must be a Hash', err.message)
    end
  end

  def test_the_instance_call_method
    result = Multiply.new(a: 2, b: 2).call

    assert_mc_success(result)
    assert_equal(4, result.value)
    assert_mc_result(result)

    result = Multiply.new(a: 1, b: '1').call

    assert(result.failure?)
    assert_equal([1, '1'], result.value)
    assert_mc_result(result)

    result
      .on_failure(:invalid_data) { |(a, _b), _use_case| assert_equal(1, a) }
      .on_failure(:invalid_data) { |(_a, b), _use_case| assert_equal('1', b) }
      .on_failure(:invalid_data) do |_value, use_case|
        assert_instance_of(Multiply, use_case)
      end
  end

  def test_the_class_call_method
    result = Double.call(number: 3)

    assert_mc_success(result)
    assert_equal(6, result.value)
    assert_mc_result(result)

    result = Double.call(number: 0)

    assert(result.failure?)
    assert_equal('number must be greater than 0', result.value)
    assert_mc_result(result)
  end

  def test_the_data_validation_error_when_calling_the_call_class_method
    [nil, 1, true, '', []].each do |arg|
      err = assert_raises(ArgumentError) { Multiply.call(arg) }
      assert_equal('argument must be a Hash', err.message)
    end
  end

  class Foo < Micro::Case::Base
  end

  def test_the_template_method
    assert_raises(NotImplementedError) { Micro::Case::Base.call }
    assert_raises(NotImplementedError) { Micro::Case::Base.new({}).call }

    assert_raises(NotImplementedError) { Foo.call }
    assert_raises(NotImplementedError) { Foo.new({}).call }
  end

  class LoremIpsum < Micro::Case::Base
    attributes :text

    def call!
      text
    end
  end

  def test_the_result_error
    err1 = assert_raises(Micro::Case::Error::UnexpectedResult) { LoremIpsum.call(text: 'lorem ipsum') }
    assert_equal('Micro::Case::BaseTest::LoremIpsum#call! must return an instance of Micro::Case::Result', err1.message)

    err2 = assert_raises(Micro::Case::Error::UnexpectedResult) { LoremIpsum.new(text: 'ipsum indolor').call }
    assert_equal('Micro::Case::BaseTest::LoremIpsum#call! must return an instance of Micro::Case::Result', err2.message)
  end

  def test_that_sets_a_result_object_avoiding_the_use_case_to_create_one
    result_instance = Micro::Case::Result.new

    use_case = Multiply.new(a: 3, b: 2)
    use_case.__set_result__(result_instance)

    result = use_case.call

    assert_same(result_instance, result)
  end

  def test_the_error_when_trying_to_set_an_invalid_result_object
    use_case = Multiply.new(a: 3, b: 2)

    err = assert_raises(ArgumentError) { use_case.__set_result__([]) }
    assert_equal('argument must be an instance of Micro::Case::Result', err.message)
  end

  def test_when_already_exists_a_result_and_tries_to_set_a_new_one
    use_case = Multiply.new(a: 3, b: 2)
    use_case.call

    err = assert_raises(ArgumentError) { use_case.__set_result__(Micro::Case::Result.new) }
    assert_equal('result is already defined', err.message)
  end

  class Divide < Micro::Case::Base
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

  def test_to_proc
    results = [
      {a: 1, b: 2},
      {a: 2, b: 2},
      {a: 3, b: 2},
      {a: 4, b: 2}
    ].map(&Multiply)

    values = results.map(&:value)

    assert_equal([2, 4, 6, 8], values)
  end
end
