require 'ostruct'
require 'test_helper'
require 'support/steps'

class Micro::Case::CallTest < Minitest::Test
  Failure = Micro::Case::Result

  Add2ToAllNumbers1 = Micro::Case::Flow([
    Steps::ConvertToNumbers,
    Steps::Add2
  ])

  def test_the_calling_of_use_cases
    assert_raises(ArgumentError) { Steps::ConvertToNumbers.new() }

    assert_instance_of(Failure, Steps::ConvertToNumbers.new({}).call)
    assert_instance_of(Failure, Steps::ConvertToNumbers.call({}))
    assert_instance_of(Failure, Steps::ConvertToNumbers.call)
  end

  def test_the_calling_of_collection_mapper_flows
    assert_raises(NoMethodError) { Add2ToAllNumbers1.new({}).call }

    assert_instance_of(Failure, Add2ToAllNumbers1.call({}))
    assert_instance_of(Failure, Add2ToAllNumbers1.call)
  end
end
