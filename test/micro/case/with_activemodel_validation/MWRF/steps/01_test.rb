require 'test_helper'

if ENV.fetch('ACTIVERECORD_VERSION', '7') <= '6.1.0'
  require_relative '../users_entity'
  require_relative '../shared_assertions'

  class Micro::Case::MWRF::WithValidation
    class Step01Test < Minitest::Test
      include SharedAssertions

      module Users::Creation1
        require 'uri'
        require 'securerandom'

        class Process < Micro::Case
          attributes :name, :email

          def call!
            normalized_name = String(name).strip.gsub(/\s+/, ' ')
            normalized_email = String(email).downcase.strip

            validation_errors = []
            validation_errors << "Name can't be blank" if normalized_name.empty?
            validation_errors << "Email is invalid" if normalized_email !~ URI::MailTo::EMAIL_REGEXP

            if !validation_errors.empty?
              return Failure :invalid_attributes, result: {
                errors: OpenStruct.new(full_messages: validation_errors)
              }
            end

            user = Users::Entity.new(
              id: SecureRandom.uuid,
              name: normalized_name,
              email: normalized_email
            )

            Success result: { user: user, crm_id: sync_with_crm }
          end

          private def sync_with_crm
            # Do some integration stuff...
            SecureRandom.uuid
          end
        end
      end

      def use_case
        Users::Creation1::Process
      end

    end
  end
end
