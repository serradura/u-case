require 'test_helper'
require_relative 'pipeline/steps'

class Micro::Service::PipelineTest < Minitest::Test
  module Jobs
    require 'securerandom'

    class Sleeping < Micro::Service::Base
      attributes :id, state: 'sleeping'

      def sleeping?
        state == 'slepping'
      end

      def call!
        job = self.with_attribute(:id, SecureRandom.uuid)

        Success(job: job)
      end
    end

    class Run < Micro::Service::Strict
      attribute :job

      def call!
        return Failure(:invalid_state_transition) unless job.sleeping?

        job_running = job.with_attribute('running')

        Succes(:state_updated) do
          {job: job_running, changes: job.diff_attributes(job_running) }
        end
      end
    end
  end

  def test_calling_with_a_result
    pipeline = Micro::Service::Pipeline[Jobs::Run]

    previous_result =
      pipeline
        .call(Jobs::Sleeping.call)
        .on_success(:state_updated) do |job:, changes:|
          assert(changes.changed?(:state, from: 'sleeping', to: 'running'))
        end

    pipeline
      .call(previous_result)
      .on_success { raise }
      .on_failure do |value|
        assert_equal(:invalid_state_transition, value)
      end
  end
end
