require 'test_helper'

class Micro::Case::ThenTest < Minitest::Test
  class Add1 < Micro::Case
    attribute :number

    def call!
      Success result: { number: number + 1 }
    end
  end

  if RUBY_VERSION < '2.5.0'
    def test_the_not_implemented_error
      assert_raises(NotImplementedError) { Add1.then { 0 } }
    end
  end

  def test_the_invalid_invocation_error
    assert_raises_with_message(
      Micro::Case::Error::InvalidInvocationOfTheThenMethod,
      'Invalid invocation of the Micro::Case.then method'
    ) { Add1.then(1) }

    if RUBY_VERSION >= '2.5.0'
      assert_raises_with_message(
        Micro::Case::Error::InvalidInvocationOfTheThenMethod,
        'Invalid invocation of the Micro::Case.then method'
      ) { Add1.then(1) { 0 } }

      Add1.then { |arg| assert_same(Add1, arg) }
    end
  end
end
