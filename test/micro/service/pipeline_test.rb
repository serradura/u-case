require 'test_helper'
require 'support/jobs'

class Micro::Service::PipelineTest < Minitest::Test
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
      .on_failure { |value| assert_equal(:invalid_state_transition, value) }
  end

  def test_calling_with_a_pipeline
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

  def test_calling_with_a_pipeline
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

  def test_calling_with_a_service_instance
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
      .on_failure { |value| assert_equal(:invalid_state_transition, value) }
  end

  def test_calling_with_a_service_class
    Jobs::Run
      .call(Jobs::State::Default)
      .on_success { raise }
      .on_failure(:invalid_uuid) { |job| assert_nil(job.id) }
      .on_failure(:invalid_uuid) do |_job, service|
        assert_instance_of(Jobs::ValidateID, service)
      end
  end
end
