require 'test_helper'

class Micro::Service::PipelineTest < Minitest::Test
  module Steps
    class ConvertToNumbers < Micro::Service::Base
      attribute :relation

      def call!
        if relation.all? { |value| String(value) =~ /\d+/ }
          Success do
            { numbers: relation.map(&:to_i) }
          end
        else
          Failure('relation must contain only numbers')
        end
      end
    end

    class Add2 < Micro::Service::Strict::Base
      attribute :numbers

      def call!
        Success(numbers.map { |number| number + 2 })
      end
    end

    class Double < Micro::Service::Strict::Base
      attribute :numbers

      def call!
        Success(numbers.map { |number| number * number })
      end
    end
  end

  Add2ToAllNumbers = Micro::Service::Pipeline[
    Steps::ConvertToNumbers,
    Steps::Add2
  ]

  DoubleAllNumbers = Micro::Service::Pipeline[
    Steps::ConvertToNumbers,
    Steps::Double
  ]

  def test_success
    result = Add2ToAllNumbers.call(relation: %w[1 1 2 2 3 4])

    assert(result.success?)
    assert_instance_of(Micro::Service::Result, result)
    result.on_success { |value| assert_equal([3, 3, 4, 4, 5, 6], value) }

    # ---

    pipeline = DoubleAllNumbers.call(relation: %w[1 1 2 2 3 4])

    assert(pipeline.success?)
    assert_instance_of(Micro::Service::Result, pipeline)
    pipeline.on_success { |value| assert_equal([1, 1, 4, 4, 9, 16], value) }
  end

  def test_failure
    result = Add2ToAllNumbers.call(relation: %w[1 1 2 a 3 4])

    assert(result.failure?)
    assert_instance_of(Micro::Service::Result, result)
    result.on_failure { |value| assert_equal('relation must contain only numbers', value) }

    # ---

    pipeline = DoubleAllNumbers.call(relation: %w[1 1 b 2 3 4])

    assert(pipeline.failure?)
    assert_instance_of(Micro::Service::Result, pipeline)
    pipeline.on_failure { |value| assert_equal('relation must contain only numbers', value) }
  end

  def test_invalid_services_error
    err = assert_raises(ArgumentError) { Micro::Service::Pipeline[Hash] }
    assert_equal('argument must be a collection of `Micro::Service::Base` classes', err.message)
  end
end
