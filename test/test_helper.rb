require 'simplecov'

SimpleCov.start do
  add_filter "/test/"
end

if ENV.fetch('ACTIVEMODEL_VERSION', '6.1') < '4.1'
  require 'minitest/unit'

  module Minitest
    Test = MiniTest::Unit::TestCase
  end
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'micro/case'

require 'minitest/autorun'

module MicroCaseAssertions
  def assert_raises_with_message(exception, msg, &block)
    block.call
  rescue exception => e
    assert_match(msg, e.message)
  else
    raise "Expected to raise #{exception} w/ message #{msg}, none raised"
  end

  def assert_kind_of_result(result)
    assert_kind_of(Micro::Case::Result, result)
  end

  # assert*result

  def assert_result(result, value: :____skip____, type: :____skip____)
    assert_kind_of_result(result)
    yield if block_given?
    assert_equal(type, result.type) if type != :____skip____
    assert_equal(value, result.value) if value != :____skip____
  end

  def assert_success_result(result, value: :____skip____, type: :ok)
    assert_result(result, value: value, type: type) do
      assert_predicate(result, :success?)
    end
  end

  def assert_failure_result(result, value: :____skip____, type: :____skip____)
    assert_result(result, value: value, type: type) do
      assert_predicate(result, :failure?)
    end
  end

  def assert_exception_result(result, value: :____skip____, type: :exception)
    assert_kind_of_result(result)
    assert_predicate(result, :failure?)
    assert_equal(type, result.type)
    assert_kind_of(value, result.value) if value != :____skip____
  end

  # refute*result

  def refute_result(result, value: :____skip____)
    assert_kind_of_result(result)
    yield if block_given?
    refute_equal(value, result.value) if value != :____skip____
  end

  def refute_success_result(result, value: :____skip____)
    refute_result(result, value: value) { refute_predicate(result, :success?) }
  end

  def refute_failure_result(result, value: :____skip____)
    refute_result(result, value: value) { refute_predicate(result, :failure?) }
  end
end

Minitest::Test.send(:include, MicroCaseAssertions)
