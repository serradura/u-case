require 'ostruct'
require 'test_helper'
require 'support/steps'

class Micro::Case::CallingTest < Minitest::Test
  Failure = Micro::Case::Result

  Add2ToAllNumbers1 = Micro::Case::Flow([
    Steps::ConvertToNumbers,
    Steps::Add2
  ])

  class Add2ToAllNumbers2
    include Micro::Case::Flow

    flow Steps::ConvertToNumbers, Steps::Add2
  end

  Add2ToAllNumbers3 = Steps::ConvertToNumbers >> Steps::Add2

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

  def test_the_calling_of_flow_classes
    assert_raises(ArgumentError) { Add2ToAllNumbers2.new() }
    assert_instance_of(Failure, Add2ToAllNumbers2.new({}).call)
    assert_instance_of(Failure, Add2ToAllNumbers2.call({}))
    assert_instance_of(Failure, Add2ToAllNumbers2.call)
  end

  def test_the_calling_of_flow_classes
    assert_raises(ArgumentError) { Add2ToAllNumbers2.new() }
    assert_instance_of(Failure, Add2ToAllNumbers2.new({}).call)
    assert_instance_of(Failure, Add2ToAllNumbers2.call({}))
    assert_instance_of(Failure, Add2ToAllNumbers2.call)
  end

  def test_the_calling_of_a_flow_created_from_composition_operators
    def test_the_calling_of_collection_mapper_flows
      assert_raises(NoMethodError) { Add2ToAllNumbers3.new({}).call }

      assert_instance_of(Failure, Add2ToAllNumbers3.call({}))
      assert_instance_of(Failure, Add2ToAllNumbers3.call)
    end
  end
end
