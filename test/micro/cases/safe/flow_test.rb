require 'test_helper'
require 'support/jobs/safe'

class Micro::Cases::Safe::FlowTest < Minitest::Test
  def test_calling_with_a_result
    new_job = Jobs::Build.call

    result1 = Jobs::Run.call(new_job)

    result1.on_success(:state_updated) do |job:, changes:|
      refute(job.sleeping?)
      assert(changes.changed?(:state, from: 'sleeping', to: 'running'))
    end

    result2 =
      Jobs::Run
        .call(result1)
        .on_success { raise }
        .on_failure { |(value, _type)| assert_equal({ invalid_state_transition: true }, value) }

    result1.transitions.tap do |result_transitions|
      assert_equal(2, result_transitions.size)

      # --------------
      # transitions[0]
      # --------------
      first_transition = result_transitions[0]

      # transitions[0][:use_case]
      first_transition_use_case = first_transition[:use_case]

      # transitions[0][:use_case][:class]
      assert_equal(Jobs::ValidateID, first_transition_use_case[:class])

      # transitions[0][:use_case][:attributes]
      assert_equal([:job], first_transition_use_case[:attributes].keys)

      assert_instance_of(Jobs::Entity, first_transition_use_case[:attributes][:job])
      assert_equal('sleeping', first_transition_use_case[:attributes][:job].state)

      # transitions[0][:success]
      assert(first_transition.include?(:success))

      first_transition_result = first_transition[:success]

      # transitions[0][:success][:type]
      assert_equal(:ok, first_transition_result[:type])

      # transitions[0][:success][:value]
      assert_equal([:job], first_transition_result[:value].keys)

      assert_instance_of(Jobs::Entity, first_transition_result[:value][:job])
      assert_equal('sleeping', first_transition_result[:value][:job].state)

      # transitions[0][:accessible_attributes]
      assert_equal([:job], first_transition[:accessible_attributes])

      # --------------
      # transitions[1]
      # --------------

      second_transition = result_transitions[1]

      # transitions[1][:use_case]

      second_transition_use_case = second_transition[:use_case]

      # transitions[1][:use_case][:class]
      assert_equal(Jobs::SetStateToRunning, second_transition_use_case[:class])

      # transitions[1][:use_case][:attributes]
      assert_equal([:job], second_transition_use_case[:attributes].keys)

      assert_instance_of(Jobs::Entity, second_transition_use_case[:attributes][:job])
      assert_equal('sleeping', second_transition_use_case[:attributes][:job].state)

      # transitions[1][:success]
      assert(second_transition.include?(:success))

      second_transition_result = second_transition[:success]

      # transitions[1][:success][:type]
      assert_equal(:state_updated, second_transition_result[:type])

      # transitions[1][:success][:value]
      assert_equal([:job, :changes], second_transition_result[:value].keys)

      assert_instance_of(Jobs::Entity, second_transition_result[:value][:job])
      assert_equal('running', second_transition_result[:value][:job].state)

      # transitions[1][:accessible_attributes]
      assert_equal([:job], second_transition[:accessible_attributes])
    end

    result2.transitions.tap do |result_transitions|
      assert_equal(2, result_transitions.size)

      # --------------
      # transitions[0]
      # --------------
      first_transition = result_transitions[0]

      # transitions[0][:use_case]
      first_transition_use_case = first_transition[:use_case]

      # transitions[0][:use_case][:class]
      assert_equal(Jobs::ValidateID, first_transition_use_case[:class])

      # transitions[0][:use_case][:attributes]
      assert_equal([:job], first_transition_use_case[:attributes].keys)

      assert_instance_of(Jobs::Entity, first_transition_use_case[:attributes][:job])
      assert_equal('running', first_transition_use_case[:attributes][:job].state)

      # transitions[0][:success]
      assert(first_transition.include?(:success))

      first_transition_result = first_transition[:success]

      # transitions[0][:success][:type]
      assert_equal(:ok, first_transition_result[:type])

      # transitions[0][:success][:value]
      assert_equal([:job], first_transition_result[:value].keys)

      assert_instance_of(Jobs::Entity, first_transition_result[:value][:job])
      assert_equal('running', first_transition_result[:value][:job].state)

      # transitions[0][:accessible_attributes]
      assert_equal([:job, :changes], first_transition[:accessible_attributes])

      # --------------
      # transitions[1]
      # --------------

      second_transition = result_transitions[1]

      # transitions[1][:use_case]
      second_transition_use_case = second_transition[:use_case]

      # transitions[1][:use_case][:class]
      assert_equal(Jobs::SetStateToRunning, second_transition_use_case[:class])

      # transitions[1][:use_case][:attributes]
      assert_equal([:job], second_transition_use_case[:attributes].keys)

      assert_instance_of(Jobs::Entity, second_transition_use_case[:attributes][:job])
      assert_equal('running', second_transition_use_case[:attributes][:job].state)

      # transitions[1][:failure]
      assert(second_transition.include?(:failure))

      second_transition_result = second_transition[:failure]

      # transitions[1][:failure][:type]
      assert_equal(:invalid_state_transition, second_transition_result[:type])

      # transitions[1][:failure][:value]
      assert_equal({ invalid_state_transition: true }, second_transition_result[:value])

      # transitions[1][:accessible_attributes]
      assert_equal([:job, :changes], second_transition[:accessible_attributes])
    end
  end

  def test_calling_with_a_flow
    result = Jobs::Run.call(Jobs::Build)

    result.on_success(:state_updated) do |job:, changes:|
      refute(job.sleeping?)
      assert(changes.changed?(:state, from: 'sleeping', to: 'running'))
    end

    Jobs::Run
      .call(result)
      .on_success { raise }
      .on_failure { |(value, *)| assert_equal({ invalid_state_transition: true }, value) }
  end

  def test_calling_with_a_use_case_instance
    job = Jobs::Entity.new(state: 'sleeping', id: nil)

    set_job_id = Jobs::SetID.new(job: job)

    result = Jobs::Run.call(set_job_id)

    result.on_success(:state_updated) do |job:, changes:|
      refute(job.sleeping?)
      assert(changes.changed?(:state, from: 'sleeping', to: 'running'))
    end

    Jobs::Run
      .call(result)
      .on_success { raise }
      .on_failure { |(value, _type)| assert_equal({ invalid_state_transition: true }, value) }
  end

  def test_calling_with_a_use_case_class
    Jobs::Run
      .call(Jobs::State::Default)
      .on_success { raise }
      .on_failure(:invalid_uuid) { |result| assert_nil(result[:job].id) }
      .on_failure(:invalid_uuid) do |_job, use_case|
        assert_instance_of(Jobs::ValidateID, use_case)
      end
  end

  def test_to_proc
    sleeping_jobs =
      [Jobs::Build, Jobs::Build, Jobs::Build].map(&:call).map(&:value)

    results = sleeping_jobs.map(&Jobs::Run)

    assert results.all?(&:success?)

    results.map(&:value).each do |job:, changes:|
      refute(job.sleeping?)
      assert(changes.changed?(:state, from: 'sleeping', to: 'running'))
    end
  end
end
