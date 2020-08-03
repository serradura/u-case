require 'test_helper'

class Micro::Cases::MapTest < Minitest::Test
  def test_the_data_array_validation_error_when_calling_the_build_method
    [nil, 1, true, '', {}].each do |arg|
      assert_raises_with_message(Kind::Error, "#{arg} expected to be a kind of Array") do
        Micro::Cases::Map.build(arg)
      end
    end
  end

  class Foo < Micro::Case
    attribute :foo

    def call!
      return Success(:filled_foo) if foo

      Failure(:missing_foo)
    end
  end

  class Bar < Micro::Case
    attribute :bar

    def call!
      return Success(:filled_bar) if bar

      Failure(:missing_bar)
    end
  end

  class FooOrBar < Micro::Case
    attributes :foo, :bar

    def call!
      return Success(:filled_foo_or_bar) if foo || bar

      Failure(:missing_foo_and_bar)
    end
  end

  class FooAndBar < Micro::Case
    attributes :foo, :bar

    def call!
      return Success(:filled_foo_and_bar) if foo && bar

      Failure(:missing_foo_or_bar)
    end
  end

  def test_result_have_success_and_failure
    results = Micro::Cases.map([Foo,
                                Bar,
                                FooOrBar,
                                FooAndBar]).call(foo: 'foo')

    assert_equal(results.select(&:success?).map { |result| result.use_case.class }, [Foo, FooOrBar])
    assert_equal(results.select(&:failure?).map { |result| result.use_case.class }, [Bar, FooAndBar])
  end

  def test_build_succes_with_dependencies_injection
    results = Micro::Cases.map([Foo,
                                FooOrBar,
                                [FooAndBar, bar: 'bar']]).call(foo: 'foo')

    assert(results.all?(&:success?))
  end
end
