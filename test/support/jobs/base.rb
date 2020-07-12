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
        Success(job: Entity.new(id: nil, state: 'sleeping'))
      end
    end

    Default = Sleeping
  end

  class SetID < Micro::Case::Strict
    ACCEPTABLE_UUID = %r{\A(\{)?([a-fA-F0-9]{4}-?){8}(?(1)\}|)\z}

    attributes :job

    def call!
      return Success(job: job) if !job.id.nil?

      Success(job: job.with_attribute(:id, SecureRandom.uuid))
    end
  end

  class ValidateID < Micro::Case::Strict
    ACCEPTABLE_UUID = %r{\A(\{)?([a-fA-F0-9]{4}-?){8}(?(1)\}|)\z}

    attributes :job

    def call!
      return Success(job: job) if job.id =~ ACCEPTABLE_UUID

      Failure(:invalid_uuid) { job }
    end
  end

  class SetStateToRunning < Micro::Case::Strict
    attribute :job

    def call!
      return Failure(:invalid_state_transition) unless job.sleeping?

      job_running = job.with_attribute(:state, 'running')

      Success(:state_updated) do
        {job: job_running, changes: job.diff_attributes(job_running) }
      end
    end
  end

  Build = Micro::Case::Flow([
    State::Default,
    SetID
  ])

  Run = Micro::Case::Flow([
    ValidateID,
    SetStateToRunning
  ])
end
