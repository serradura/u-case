require 'test_helper'
require 'support/jobs'

class Micro::Case::FlowTest < Minitest::Test
  def test_calling_with_a_result
    new_job = Jobs::Build.call

    result = Jobs::Run.call(new_job)

    result.on_success(:state_updated) do |job:, changes:|
      refute(job.sleeping?)
      assert(changes.changed?(:state, from: 'sleeping', to: 'running'))
    end

    Jobs::Run
      .call(result)
      .on_success { raise }
      .on_failure do |(value, _type)|
        assert_equal(:invalid_state_transition, value)
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
      .on_failure { |value| assert_equal(:invalid_state_transition, value) }
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
      .on_failure { |(value, _type)| assert_equal(:invalid_state_transition, value) }
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
      .on_failure { |data| assert_equal(:invalid_state_transition, data.value) }
  end

  def test_calling_with_a_use_case_class
    Jobs::Run
      .call(Jobs::State::Default)
      .on_success { raise }
      .on_failure(:invalid_uuid) { |job| assert_nil(job.id) }
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
