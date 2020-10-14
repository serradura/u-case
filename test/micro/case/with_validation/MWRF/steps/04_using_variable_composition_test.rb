require 'test_helper'

if ENV.fetch('ACTIVEMODEL_VERSION', '6.1') <= '6.0.0'
  require_relative '../users_entity'
  require_relative '../shared_assertions'

  class Micro::Case::MWRF::WithValidation
    class Step04UsingVariableCompositionTest < Minitest::Test
      include SharedAssertions

      module Users::Creation4c
        class NormalizeParams < Micro::Case
          attributes :name, :email

          def call!
            normalized_name = String(name).strip.gsub(/\s+/, ' ')
            normalized_email = String(email).downcase.strip

            Success result: { name: normalized_name, email: normalized_email }
          end
        end
      end

      module Users::Creation4c
        require 'uri'

        class ValidateParams < Micro::Case
          attribute :name, validates: { presence: true }
          attribute :email, validates: { format: URI::MailTo::EMAIL_REGEXP }

          def call!
            Success result: attributes(:name, :email)
          end
        end
      end

      require 'securerandom'

      module Users::Creation4c
        class Persist < Micro::Case
          attributes :name, :email, validates: { kind: String }

          def call!
            user_data = attributes.merge(id: SecureRandom.uuid)

            Success result: { user: Users::Entity.new(user_data) }
          end
        end
      end

      module Users::Creation4c
        class SyncWithCRM < Micro::Case
          attribute :user, validates: { kind: Users::Entity }

          def call!
            if user.persisted?
              Success result: { user: user, crm_id: sync_with_crm }
            else
              Failure :sync_failed, result: { message: "User can't be sent to the CRM" }
            end
          end

          private def sync_with_crm
            # Do some integration stuff...
            SecureRandom.uuid
          end
        end
      end

      module Users::Creation4c
        class Process < Micro::Case
          def call!
            call(NormalizeParams)
              .then(ValidateParams)
              .then(Persist)
              .then(SyncWithCRM)
          end
        end
      end

      def use_case
        Users::Creation4c::Process
      end

    end
  end
end
