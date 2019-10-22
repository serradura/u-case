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
  def assert_kind_of_result(result)
    assert_kind_of(Micro::Case::Result, result)
  end

  # assert*result

  def assert_result(result, value: :____skip____)
    assert_kind_of_result(result)

    yield if block_given?

    assert_equal(value, result.value) unless value == :____skip____
  end

  def assert_success_result(result, value: :____skip____)
    assert_result(result, value: value) { assert_predicate(result, :success?) }
  end

  def assert_failure_result(result, value: :____skip____)
    assert_result(result, value: value) { assert_predicate(result, :failure?) }
  end

  # refute*result

  def refute_result(result, value: :____skip____)
    assert_kind_of_result(result)

    yield if block_given?

    refute_equal(value, result.value) unless value == :____skip____
  end

  def refute_success_result(result, value: :____skip____)
    refute_result(result, value: value) { refute_predicate(result, :success?) }
  end

  def refute_failure_result(result, value: :____skip____)
    refute_result(result, value: value) { refute_predicate(result, :failure?) }
  end
end

Minitest::Test.send(:include, MicroCaseAssertions)
