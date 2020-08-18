require 'test_helper'

class Micro::Cases::Flow::ThenTest < Minitest::Test
  class Add1 < Micro::Case
    attribute :number

    def call!
      Success result: { number: number + 1 }
    end
  end

  Add2 = Micro::Cases.flow([
    Add1, Add1
  ])

  class Add3 < Micro::Case
    flow([Add1, Add1, Add1])
  end

  if RUBY_VERSION < '2.5.0'
    def test_the_not_implemented_error
      assert_raises(NotImplementedError) { Add2.then { 0 } }
      assert_raises(NotImplementedError) { Add3.then { 0 } }
    end
  end

  def test_the_invalid_invocation_error
    assert_raises_with_message(
      Micro::Case::Error::InvalidInvocationOfTheThenMethod,
      'Invalid invocation of the Micro::Cases::Flow#then method'
    ) { Add2.then(1) }

    assert_raises_with_message(
      Micro::Case::Error::InvalidInvocationOfTheThenMethod,
      'Invalid invocation of the Micro::Case.then method'
    ) { Add3.then(1) }

    if RUBY_VERSION >= '2.5.0'
      assert_raises_with_message(
        Micro::Case::Error::InvalidInvocationOfTheThenMethod,
        'Invalid invocation of the Micro::Cases::Flow#then method'
      ) { Add2.then(1) { 0 } }

      assert_raises_with_message(
        Micro::Case::Error::InvalidInvocationOfTheThenMethod,
        'Invalid invocation of the Micro::Case.then method'
      ) { Add3.then(1) { 0 } }

      Add2.then { |arg| assert_same(Add2, arg) }
      Add3.then { |arg| assert_same(Add3, arg) }
    end
  end
end
