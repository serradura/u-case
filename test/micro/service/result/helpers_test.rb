require 'test_helper'

class Micro::Service::Result::HelpersTest < Minitest::Test
  class Klass1
    include Micro::Service::Result::Helpers

    def initialize(data)
      @data = data
    end

    def success
      Success(@data)
    end

    def failure
      Failure(@data)
    end
  end

  class Klass2
    include Micro::Service::Result::Helpers

    def initialize(data)
      @data = data
    end

    def success
      Success do
        @data
      end
    end

    def failure
      Failure do
        @data
      end
    end
  end

  Person = Struct.new(:name)

  def test_success_result
    person = Person.new('Serradura')

    instance1 = Klass1.new(person)
    instance2 = Klass2.new(person)

    result1 = instance1.success
    result2 = instance2.success

    assert(result1.success?)
    assert_instance_of(Micro::Service::Result, result1)
    result1.on_success { |value| assert_equal('Serradura', value.name) }

    assert(result2.success?)
    assert_instance_of(Micro::Service::Result, result2)
    result2.on_success { |value| assert_equal('Serradura', value.name) }
  end

  def test_failure_result
    person = Person.new('Serradura')

    instance1 = Klass1.new(person)
    instance2 = Klass2.new(person)

    result1 = instance1.failure
    result2 = instance2.failure

    assert(result1.failure?)
    assert_instance_of(Micro::Service::Result, result1)
    result1.on_failure { |value| assert_equal('Serradura', value.name) }

    assert(result2.failure?)
    assert_instance_of(Micro::Service::Result, result2)
    result2.on_failure { |value| assert_equal('Serradura', value.name) }
  end
end
