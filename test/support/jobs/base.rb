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
    class Sleeping < Micro::Case
      def call!
        job = Entity.new(id: nil, state: 'sleeping')

        Success result: { job: job }
      end
    end

    Default = Sleeping
  end

  class SetID < Micro::Case::Strict
    ACCEPTABLE_UUID = %r{\A(\{)?([a-fA-F0-9]{4}-?){8}(?(1)\}|)\z}

    attributes :job

    def call!
      return Success result: { job: job } if !job.id.nil?

      new_job = job.with_attribute(:id, SecureRandom.uuid)

      Success result: { job: new_job }
    end
  end

  class ValidateID < Micro::Case::Strict
    ACCEPTABLE_UUID = %r{\A(\{)?([a-fA-F0-9]{4}-?){8}(?(1)\}|)\z}

    attributes :job

    def call!
      return Success result: { job: job } if job.id =~ ACCEPTABLE_UUID

      Failure :invalid_uuid, result: { job: job }
    end
  end

  class SetStateToRunning < Micro::Case::Strict
    attribute :job

    def call!
      return Failure(:invalid_state_transition) unless job.sleeping?

      job_running = job.with_attribute(:state, 'running')

      Success :state_updated, result: {
        job: job_running, changes: job.diff_attributes(job_running)
      }
    end
  end

  Build = Micro::Cases.flow([
    State::Default,
    SetID
  ])

  Run = Micro::Cases.flow([
    ValidateID,
    SetStateToRunning
  ])
end
