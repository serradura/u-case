require 'pry-byebug'

if RUBY_VERSION >= '2.4.0'
  require 'simplecov'

  SimpleCov.start do
    add_filter '/test/'

    enable_coverage :branch if RUBY_VERSION >= '2.5.0'
  end
end

if ENV.fetch('ACTIVERECORD_VERSION', '7') < '4.1'
  require 'minitest/unit'

  module Minitest
    Test = MiniTest::Unit::TestCase
  end
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'u-case'

Micro::Case.config do |config|
  enable_activemodel = ENV.fetch('ACTIVERECORD_VERSION', '7') < '6.1.0'

  config.enable_activemodel_validation = enable_activemodel

  enable_transitions = ENV.fetch('ENABLE_TRANSITIONS', 'true') == 'true'

  config.enable_transitions = enable_transitions
end

require 'minitest/pride'
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

  def assert_result(result, options)
    type = options[:type] || :____skip____
    value = options[:value] || :____skip____

    assert_kind_of_result(result)
    assert_predicate(result.data, :frozen?)
    assert_equal(type, result.type) if type != :____skip____
    assert_equal(value, result.value) if value != :____skip____
  end

  def assert_success_result(result, options = { type: :ok })
    value = (block_given? ? yield : options[:value])

    assert_result(result, options.merge(value: value)) if value

    assert_predicate(result, :success?)

    # assert the on_success hook
    count = 0
    result
      .on_failure { raise } # should never be called, because is a successful result.
      .on_success { count += 1 }
      .on_success(options[:type]) { count += 1 }

    assert_equal(2, count)
  end

  def assert_failure_result(result, options = {})
    value = (block_given? ? yield : options[:value])

    assert_result(result, options.merge(value: value))

    assert_predicate(result, :failure?)

    # assert the on_failure hook

    count = 0
    result
      .on_success { raise } # should never be called, because is a failure result.
      .on_failure { count += 1 }
      .on_failure(options[:type]) { count += 1 }

    assert_equal(2, count)
  end

  def assert_exception_result(result, value: :____skip____, type: :exception)
    assert_kind_of_result(result)
    assert_equal(type, result.type)
    assert_kind_of(value[:exception], result.value[:exception]) if value != :____skip____
    assert_predicate(result, :failure?)

    # assert the on_failure hook

    count = 0
    result
      .on_success { raise } # should never be called, because is a failure result.
      .on_failure { count += 1 }
      .on_failure(type) { count += 1 }
      .on_failure(:error) { raise } # will be avoided

    assert_equal(2, count)
  end

  # refute*result

  def refute_result(result, options)
    type = options[:type] || :____skip____
    value = options[:value] || :____skip____

    assert_kind_of_result(result)
    refure_equal(type, result.type) if type != :____skip____
    refute_equal(value, result.value) if value != :____skip____
  end

  def refute_success_result(result, options = {})
    value = (block_given? ? yield : options[:value])

    refute_result(result, options.merge(value: value))
    refute_predicate(result, :success?)
  end

  def refute_failure_result(result, options = {})
    value = (block_given? ? yield : options[:value])

    refute_result(result, options.merge(value: value))
    refute_predicate(result, :failure?)
  end
end

Minitest::Test.send(:include, MicroCaseAssertions)
