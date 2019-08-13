require 'test_helper'
require_relative 'pipeline/steps'

class Micro::Service::PipelineTest < Minitest::Test
  require 'securerandom'

  module Jobs
    class Entity
      include Micro::Attributes.with(:strict_initialize, :diff)

      attributes :id, :state

      def sleeping?
        state == 'sleeping'
      end
    end

    module State
      class Sleeping < Micro::Service::Base
        def call!
          Success(job: Entity.new(id: nil, state: 'sleeping'))
        end
      end

      Default = Sleeping
    end

    class SetID < Micro::Service::Strict
      ACCEPTABLE_UUID = %r{\A(\{)?([a-fA-F0-9]{4}-?){8}(?(1)\}|)\z}

      attributes :job

      def call!
        return Success(job: job) if !job.id.nil?

        Success(job: job.with_attribute(:id, SecureRandom.uuid))
      end
    end

    class ValidateID < Micro::Service::Strict
      ACCEPTABLE_UUID = %r{\A(\{)?([a-fA-F0-9]{4}-?){8}(?(1)\}|)\z}

      attributes :job

      def call!
        return Success(job: job) if job.id =~ ACCEPTABLE_UUID

        Failure(:invalid_uuid) { job }
      end
    end

    class SetStateToRunning < Micro::Service::Strict
      attribute :job

      def call!
        return Failure(:invalid_state_transition) unless job.sleeping?

        job_running = job.with_attribute(:state, 'running')

        Success(:state_updated) do
          {job: job_running, changes: job.diff_attributes(job_running) }
        end
      end
    end

    Build = State::Default >> SetID

    Run = ValidateID >> SetStateToRunning
  end

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
  end
end
