require 'test_helper'

class Micro::Case::Result::PatternMatchingTest < Minitest::Test
  def build_result(success:, value:, type:, use_case: nil)
    result = Micro::Case::Result.new
    result.__set__(success, value, type, use_case || Micro::Case.send(:new, {}))
    result
  end

  def success_result(options = {})
    build_result(**{ type: :ok }.merge(options).merge(success: true))
  end

  def failure_result(options = {})
    build_result(**{ type: :error }.merge(options).merge(success: false))
  end

  def test_deconstruct_returns_data_and_type
    success = success_result(value: { number: 42 }, type: :ok)
    failure = failure_result(value: { reason: 'nope' }, type: :invalid_attributes)

    assert_equal([{ number: 42 }, :ok], success.deconstruct)
    assert_equal([{ reason: 'nope' }, :invalid_attributes], failure.deconstruct)
  end

  def test_deconstruct_keys_with_nil_returns_full_hash_for_success
    result = success_result(value: { number: 42 }, type: :ok)

    hash = result.deconstruct_keys(nil)

    assert_equal(:ok, hash[:success])
    refute(hash.key?(:failure))
    assert_equal(:ok, hash[:type])
    assert_equal({ number: 42 }, hash[:data])
    assert_equal({ number: 42 }, hash[:result])
    assert_same(result.use_case, hash[:use_case])
    assert_equal(result.transitions, hash[:transitions])
  end

  def test_deconstruct_keys_with_nil_returns_full_hash_for_failure
    result = failure_result(value: { reason: 'nope' }, type: :invalid_attributes)

    hash = result.deconstruct_keys(nil)

    assert_equal(:invalid_attributes, hash[:failure])
    refute(hash.key?(:success))
    assert_equal(:invalid_attributes, hash[:type])
    assert_equal({ reason: 'nope' }, hash[:data])
    assert_equal({ reason: 'nope' }, hash[:result])
  end

  def test_deconstruct_keys_honors_requested_keys
    result = success_result(value: { number: 42 }, type: :ok)

    assert_equal({ success: :ok }, result.deconstruct_keys([:success]))
    assert_equal({ data: { number: 42 } }, result.deconstruct_keys([:data]))
    assert_equal({ result: { number: 42 } }, result.deconstruct_keys([:result]))
    assert_equal({ type: :ok }, result.deconstruct_keys([:type]))
    assert_equal({}, result.deconstruct_keys([:failure]))
    assert_equal({}, result.deconstruct_keys([:unknown_key]))
  end

  def test_pattern_match_success_with_data_key
    result = success_result(value: { number: 42 }, type: :ok)

    matched = case result
              in { success: _, data: { number: Integer => number } }
                number
              else
                :no_match
              end

    assert_equal(42, matched)
  end

  def test_pattern_match_success_with_result_alias
    result = success_result(value: { number: 42 }, type: :ok)

    matched = case result
              in { success: _, result: { number: Integer => number } }
                number
              else
                :no_match
              end

    assert_equal(42, matched)
  end

  def test_pattern_match_failure_by_type
    result = failure_result(value: { reason: 'nope' }, type: :invalid_attributes)

    matched = case result
              in { failure: :invalid_attributes }
                :got_invalid
              in { failure: _ }
                :other_failure
              end

    assert_equal(:got_invalid, matched)
  end

  def test_pattern_match_failure_does_not_match_success_pattern
    result = failure_result(value: { reason: 'nope' }, type: :invalid_attributes)

    matched = case result
              in { success: _ }
                :matched_success
              in { failure: _ }
                :matched_failure
              end

    assert_equal(:matched_failure, matched)
  end

  def test_pattern_match_success_does_not_match_failure_pattern
    result = success_result(value: { number: 42 }, type: :ok)

    matched = case result
              in { failure: _ }
                :matched_failure
              in { success: _ }
                :matched_success
              end

    assert_equal(:matched_success, matched)
  end

  def test_array_pattern_matches_data_and_type
    result = success_result(value: { number: 42 }, type: :ok)

    matched = case result
              in [{ number: Integer => number }, :ok]
                number
              else
                :no_match
              end

    assert_equal(42, matched)
  end

  def test_pattern_match_with_type_key
    result = success_result(value: { number: 42 }, type: :ok)

    matched = case result
              in { type: :ok, data: { number: number } }
                number
              else
                :no_match
              end

    assert_equal(42, matched)
  end
end
