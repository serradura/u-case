require 'test_helper'

require_relative '../users_entity'
require_relative '../shared_assertions'

class Micro::Case::MWRF
  class Step02Test < Minitest::Test
    include SharedAssertions

    module Users::Creation2
      require 'uri'
      require 'securerandom'

      class Process < Micro::Case
        attributes :name, :email

        def call!
          normalize_params
            .then(method(:validate_params))
            .then(method(:persist))
            .then(method(:sync_with_crm))
        end

        private

          def normalize_params
            Success :normalize_params, result: {
              name: String(name).strip.gsub(/\s+/, ' '),
              email: String(email).downcase.strip
            }
          end

          def validate_params(name:, email:)
            validation_errors = []
            validation_errors << "Name can't be blank" if name.empty?
            validation_errors << "Email is invalid" if email !~ URI::MailTo::EMAIL_REGEXP

            return Success(:validate_params) if validation_errors.empty?

            Failure :invalid_attributes, result: {
              errors: OpenStruct.new(full_messages: validation_errors)
            }
          end

          def persist(name:, email:, **)
            user_data = { name: name, email: email, id: SecureRandom.uuid }

            user = Users::Entity.new(user_data)

            Success :persist, result: { user: user }
          end

          def sync_with_crm(user:, **)
            if user.persisted?
              # Do some integration stuff...
              crm_id = SecureRandom.uuid

              Success :sync_with_crm, result: { user: user, crm_id: crm_id }
            else
              Failure :sync_failed, result: { message: "User can't be sent to the CRM" }
            end
          end
      end
    end

    def use_case
      Users::Creation2::Process
    end

  end
end
