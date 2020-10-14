require 'test_helper'

class Micro::Cases::MapTest < Minitest::Test
  def test_invalid_types_should_raise_an_exception
    [nil, 1, true, '', {}].each do |arg|
      assert_raises_with_message(Kind::Error, "#{arg} expected to be a kind of Array") do
        Micro::Cases::Map.build(arg)
      end
    end
  end

  def test_invalid_array_should_raise_an_exception
    assert_raises_with_message(
      Micro::Cases::Error::InvalidUseCases,
      'argument must be a collection of `Micro::Case` classes'
    ) { Micro::Cases.map(%w[wrong params]).call(foo: 'foo') }

    # --

    assert_raises_with_message(
      Micro::Cases::Error::InvalidUseCases,
      'argument must be a collection of `Micro::Case` classes'
    ) { Micro::Cases.map([String, Integer]).call(foo: 'foo') }
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

  def test_the_calling_of_use_cases_and_flows
    map_use_cases1 = Micro::Cases.map([
      Foo, Bar, FooOrBar, FooAndBar
    ])

    results1 = map_use_cases1.call(foo: 'foo')

    assert_equal(results1.select(&:success?).map { |result| result.use_case.class }, [Foo, FooOrBar])
    assert_equal(results1.select(&:failure?).map { |result| result.use_case.class }, [Bar, FooAndBar])

    # --

    flow1 = Micro::Cases.flow([Foo, Foo])
    flow2 = Micro::Cases.flow([Foo, Bar])

    map_use_cases2 = Micro::Cases.map([
      flow1, flow2, FooOrBar, FooAndBar
    ])

    results2 = map_use_cases2.call(foo: 'foo')

    assert_equal(results2.select(&:success?).map { |result| result.use_case.class }, [Foo, FooOrBar])
    assert_equal(results2.select(&:failure?).map { |result| result.use_case.class }, [Bar, FooAndBar])
  end

  def test_the_calling_with_dependency_injection
    map_use_cases = Micro::Cases.map([
      Foo, FooOrBar, [FooAndBar, bar: 'bar']
    ])

    results = map_use_cases.call(foo: 'foo')

    assert(results.all?(&:success?))
  end
end
