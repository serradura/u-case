require 'test_helper'

class Micro::Case::Result::WrapperTest < Minitest::Test
  class Echo < Micro::Case
    attribute :value

    def call!
      case value
      when :ok       then Success(:ok,       result: { value: value })
      when :created  then Success(:created,  result: { value: value })
      when :weak     then Failure(:weak,     result: { reason: 'too short' })
      when :reused   then Failure(:reused,   result: { reason: 'already used' })
      else                Success(result: { value: value })
      end
    end
  end

  # --- Backward compatibility: existing 1-arity / single-type / no-type forms

  def test_success_no_type_one_arity_receives_full_result
    captured = nil

    output = Echo.call(value: :ok) do |on|
      on.success { |r| captured = r; r.data[:value] }
    end

    assert_instance_of(Micro::Case::Result, captured)
    assert_predicate(captured, :success?)
    assert_equal(:ok, captured.type)
    assert_equal(:ok, output)
  end

  def test_success_single_symbol_type_still_matches
    output = Echo.call(value: :ok) do |on|
      on.success(:ok) { |r| r.type }
    end

    assert_equal(:ok, output)
  end

  def test_failure_no_type_one_arity_receives_full_result
    captured = nil

    output = Echo.call(value: :weak) do |on|
      on.failure { |r| captured = r; r.type }
    end

    assert_instance_of(Micro::Case::Result, captured)
    assert_predicate(captured, :failure?)
    assert_equal(:weak, output)
  end

  def test_unknown_one_arity_receives_full_result
    captured = nil

    output = Echo.call(value: :ok) do |on|
      on.failure { raise }
      on.unknown { |r| captured = r; r.type }
    end

    assert_instance_of(Micro::Case::Result, captured)
    assert_equal(:ok, output)
  end

  # --- New: *types splat matching

  def test_success_splat_matches_any_listed_type
    output = Echo.call(value: :created) do |on|
      on.success(:ok, :created) { |r| r.type }
    end

    assert_equal(:created, output)
  end

  def test_success_splat_does_not_match_when_type_not_listed
    output = Echo.call(value: :ok) do |on|
      on.success(:created) { raise }
      on.success(:ok)      { |r| r.type }
    end

    assert_equal(:ok, output)
  end

  def test_failure_splat_matches_any_listed_type
    output = Echo.call(value: :reused) do |on|
      on.failure(:weak, :reused) { |r| r.type }
    end

    assert_equal(:reused, output)
  end

  # --- New: 2-arity blocks receive (data, type)

  def test_success_two_arity_block_receives_data_and_type
    captured_data = nil
    captured_type = nil

    Echo.call(value: :ok) do |on|
      on.success { |data, type| captured_data = data; captured_type = type }
    end

    assert_equal({ value: :ok }, captured_data)
    assert_equal(:ok, captured_type)
  end

  def test_failure_two_arity_block_receives_data_and_type
    captured_data = nil
    captured_type = nil

    Echo.call(value: :weak) do |on|
      on.failure { |data, type| captured_data = data; captured_type = type }
    end

    assert_equal({ reason: 'too short' }, captured_data)
    assert_equal(:weak, captured_type)
  end

  def test_unknown_two_arity_block_receives_data_and_type
    captured_data = nil
    captured_type = nil

    Echo.call(value: :ok) do |on|
      on.failure { raise }
      on.unknown { |data, type| captured_data = data; captured_type = type }
    end

    assert_equal({ value: :ok }, captured_data)
    assert_equal(:ok, captured_type)
  end

  # --- New: motivating mixed-arity shape

  def test_motivating_shape_success_one_arity_failure_two_arity
    success_capture = nil
    failure_capture = nil

    Echo.call(value: :ok) do |on|
      on.success { |r| success_capture = r }
      on.failure { |data, type| failure_capture = [data, type] }
    end

    assert_instance_of(Micro::Case::Result, success_capture)
    assert_equal(:ok, success_capture.type)
    assert_nil(failure_capture)
  end

  def test_motivating_shape_failure_path
    success_capture = nil
    failure_capture = nil

    Echo.call(value: :weak) do |on|
      on.success { |result| success_capture = result }
      on.failure { |data, type| failure_capture = [data, type] }
    end

    assert_nil(success_capture)
    assert_equal([{ reason: 'too short' }, :weak], failure_capture)
  end

  # --- Type filter that misses still leaves unknown to fire

  def test_type_filter_miss_falls_through_to_unknown
    unknown_capture = nil

    output = Echo.call(value: :ok) do |on|
      on.success(:created)        { raise }
      on.failure                  { raise }
      on.unknown                  { |r| unknown_capture = r; r.type }
    end

    assert_equal(:ok, output)
    assert_instance_of(Micro::Case::Result, unknown_capture)
  end

  # --- One-branch-wins

  def test_first_matching_success_wins
    calls = []

    output = Echo.call(value: :ok) do |on|
      on.success(:ok) { |_| calls << :first;  :one }
      on.success(:ok) { |_| calls << :second; :two }
      on.success      { |_| calls << :third;  :three }
    end

    assert_equal([:first], calls)
    assert_equal(:one, output)
  end

  # --- Return value semantics for Micro::Case.call

  def test_block_form_returns_wrapper_output
    output = Echo.call(value: :ok) do |on|
      on.success { 42 }
    end

    assert_equal(42, output)
  end

  def test_block_form_returns_kind_undefined_when_no_branch_matches
    output = Echo.call(value: :ok) do |on|
      on.failure { raise }
    end

    assert_equal(::Kind::Undefined, output)
  end

  def test_non_block_form_returns_result
    out = Echo.call(value: :ok)

    assert_instance_of(Micro::Case::Result, out)
    assert_predicate(out, :success?)
  end

  # --- unknown does not run if a success/failure branch already matched

  def test_unknown_skipped_when_success_matched
    output = Echo.call(value: :ok) do |on|
      on.success { :matched }
      on.unknown { raise }
    end

    assert_equal(:matched, output)
  end

  def test_unknown_skipped_when_failure_matched
    output = Echo.call(value: :weak) do |on|
      on.failure { :matched }
      on.unknown { raise }
    end

    assert_equal(:matched, output)
  end
end
