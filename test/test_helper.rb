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
  def assert_result(result)
    assert_kind_of(Micro::Case::Result, result)
  end

  def assert_success_result(result)
    assert_predicate(result, :success?)
  end

  def refute_success_result(result)
    refute_predicate(result, :success?)
  end

  def assert_failure_result(result)
    assert_predicate(result, :failure?)
  end

  def refute_failure_result(result)
    refute_predicate(result, :failure?)
  end
end

Minitest::Test.send(:include, MicroCaseAssertions)
