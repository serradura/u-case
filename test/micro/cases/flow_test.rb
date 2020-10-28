require 'test_helper'
require 'support/jobs/base'

class Micro::Cases::FlowTest < Minitest::Test
  def test_calling_with_a_result
    result1 = Jobs::Build.then(Jobs::Run)

    result1.on_success(:state_updated) do |data|
      job, changes = data.values_at(:job, :changes)

      refute(job.sleeping?)
      assert(changes.changed?(:state, from: 'sleeping', to: 'running'))
    end

    result1_transitions = result1.transitions

    if ::Micro::Case::Result.transitions_enabled?
      assert_equal(4, result1_transitions.size)

      {
        0 => {
          use_case: -> use_case do
            assert_equal(Jobs::Build::Self, use_case[:class])

            assert_equal({}, use_case[:attributes])
          end,
          success: -> success do
            assert_equal(:ok, success[:type])

            result = success[:result]

            assert_equal([:job], result.keys)

            job = result[:job]

            assert_nil(job.id)
            assert_predicate(job, :sleeping?)
          end,
          accessible_attributes: -> keys { assert_equal([], keys) }
        },
        1 => {
          use_case: -> (use_case, previous) do
            assert_equal(Jobs::SetID, use_case[:class])

            assert_equal(previous[:success][:result], use_case[:attributes])
          end,
          success: -> (success) do
            assert_equal(:ok, success[:type])

            result = success[:result]

            assert_equal([:job], result.keys)

            job = result[:job]

            assert_match(%r{\A(\{)?([a-fA-F0-9]{4}-?){8}(?(1)\}|)\z}, job.id)
            assert_predicate(job, :sleeping?)
          end,
          accessible_attributes: -> keys { assert_equal([:job], keys) }
        },
        2 => {
          use_case: -> (use_case, previous) do
            assert_equal(Jobs::ValidateID, use_case[:class])

            assert_equal(previous[:success][:result], use_case[:attributes])
          end,
          success: -> (success, previous) { assert_equal(previous[:success], success) },
          accessible_attributes: -> keys { assert_equal([:job], keys) }
        },
        3 => {
          use_case: -> (use_case, previous) do
            assert_equal(Jobs::SetStateToRunning, use_case[:class])

            assert_equal(previous[:success][:result], use_case[:attributes])
          end,
          success: -> (success, previous) do
            assert_equal(:state_updated, success[:type])

            result = success[:result]

            assert_equal([:job, :changes], result.keys)

            job = result[:job]

            assert_equal(previous[:success][:result][:job].id, job.id)
            assert_predicate(job, :running?)

            result[:changes].changed?(:state, from: 'sleeping', to: 'running')
          end,
          accessible_attributes: -> keys { assert_equal([:job], keys) }
        }
      }.each do |index, transition_assertions|
        transition_assertions.each do |key, assertion|
          transition_scope = result1_transitions[index][key]

          if assertion.arity == 1
            assertion.call(transition_scope)
          else
            previous_transition = result1_transitions[index - 1] if index != 0

            assertion.call(transition_scope, previous_transition)
          end
        end
      end
    else
      assert_equal([], result1_transitions)
    end

    # ---

    result2 =
      result1
        .then(Jobs::Run)
        .on_success { raise }
        .on_failure do |(value, _type)|
          assert_equal({ invalid_state_transition: true }, value)
        end

      result2_transitions = result2.transitions

    if ::Micro::Case::Result.transitions_enabled?
      assert_equal(6, result2_transitions.size)

      {
        0 => {
          use_case: -> use_case do
            assert_equal(Jobs::Build::Self, use_case[:class])

            assert_equal({}, use_case[:attributes])
          end,
          success: -> success do
            assert_equal(:ok, success[:type])

            result = success[:result]

            assert_equal([:job], result.keys)

            job = result[:job]

            assert_nil(job.id)
            assert_predicate(job, :sleeping?)
          end,
          accessible_attributes: -> keys { assert_equal([], keys) }
        },
        1 => {
          use_case: -> (use_case, previous) do
            assert_equal(Jobs::SetID, use_case[:class])

            assert_equal(previous[:success][:result], use_case[:attributes])
          end,
          success: -> (success) do
            assert_equal(:ok, success[:type])

            result = success[:result]

            assert_equal([:job], result.keys)

            job = result[:job]

            assert_match(%r{\A(\{)?([a-fA-F0-9]{4}-?){8}(?(1)\}|)\z}, job.id)
            assert_predicate(job, :sleeping?)
          end,
          accessible_attributes: -> keys { assert_equal([:job], keys) }
        },
        2 => {
          use_case: -> (use_case, previous) do
            assert_equal(Jobs::ValidateID, use_case[:class])

            assert_equal(previous[:success][:result], use_case[:attributes])
          end,
          success: -> (success, previous) { assert_equal(previous[:success], success) },
          accessible_attributes: -> keys { assert_equal([:job], keys) }
        },
        3 => {
          use_case: -> (use_case, previous) do
            assert_equal(Jobs::SetStateToRunning, use_case[:class])

            assert_equal(previous[:success][:result], use_case[:attributes])
          end,
          success: -> (success, previous) do
            assert_equal(:state_updated, success[:type])

            result = success[:result]

            assert_equal([:job, :changes], result.keys)

            job = result[:job]

            assert_equal(previous[:success][:result][:job].id, job.id)
            assert_predicate(job, :running?)

            result[:changes].changed?(:state, from: 'sleeping', to: 'running')
          end,
          accessible_attributes: -> keys { assert_equal([:job], keys) }
        },
        4 => {
          use_case: -> (use_case, previous) do
            assert_equal(Jobs::ValidateID, use_case[:class])

            attributes = use_case[:attributes]

            assert_equal([:job], attributes.keys)

            assert_equal(previous[:success][:result][:job], attributes[:job])
          end,
          success: -> (success, previous) do
            assert_equal(:ok, success[:type])

            result = success[:result]

            assert_equal([:job], result.keys)

            assert_equal(previous[:success][:result][:job], result[:job])
          end,
          accessible_attributes: -> keys { assert_equal([:job, :changes], keys) }
        },
        5 => {
          use_case: -> (use_case, previous) do
            assert_equal(Jobs::SetStateToRunning, use_case[:class])

            assert_equal(previous[:success][:result], use_case[:attributes])
          end,
          failure: -> (failure, previous) do
            assert_equal(:invalid_state_transition, failure[:type])

            assert_equal({ invalid_state_transition: true }, failure[:result])
          end,
          accessible_attributes: -> keys { assert_equal([:job, :changes], keys) }
        },
      }.each do |index, transition_assertions|
        transition_assertions.each do |key, assertion|
          transition_scope = result2_transitions[index][key]

          if assertion.arity == 1
            assertion.call(transition_scope)
          else
            previous_transition = result2_transitions[index - 1] if index != 0

            assertion.call(transition_scope, previous_transition)
          end
        end
      end
    else
      assert_equal([], result2_transitions)
    end
  end

  def test_calling_with_a_flow
    result = Jobs::Build.then(Jobs::Run)

    result.on_success(:state_updated) do |data|
      job, changes = data.values_at(:job, :changes)

      refute(job.sleeping?)
      assert(changes.changed?(:state, from: 'sleeping', to: 'running'))
    end

    result
      .then(Jobs::Run)
      .on_success { raise }
      .on_failure { |(value, _type)| assert_equal({ invalid_state_transition: true }, value) }
  end

  def test_calling_with_a_use_case_instance
    job = Jobs::Entity.new(state: 'sleeping', id: nil)

    result = Jobs::SetID.call(job: job).then(Jobs::Run)

    result.on_success(:state_updated) do |data|
      job, changes = data.values_at(:job, :changes)

      refute(job.sleeping?)
      assert(changes.changed?(:state, from: 'sleeping', to: 'running'))
    end

    result
      .then(Jobs::Run)
      .on_success { raise }
      .on_failure { |data| assert_equal({invalid_state_transition: true}, data.value) }
  end

  def test_to_proc
    sleeping_jobs =
      [Jobs::Build, Jobs::Build, Jobs::Build].map(&:call).map(&:data)

    results = sleeping_jobs.map(&Jobs::Run)

    assert results.all?(&:success?)

    results.map(&:value).each do |data|
      job, changes = data.values_at(:job, :changes)

      refute(job.sleeping?)
      assert(changes.changed?(:state, from: 'sleeping', to: 'running'))
    end
  end
end
