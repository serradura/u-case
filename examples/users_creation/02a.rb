require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'activemodel', '~> 6.0'

  gem 'u-case', '~> 3.0.0.rc9'
end

Micro::Case.config do |config|
  # Use ActiveModel to auto-validate your use cases' attributes.
  config.enable_activemodel_validation = true

  # Use to enable/disable the `Micro::Case::Results#transitions` tracking.
  config.enable_transitions = true
end

module Users
  class Entity
    include Micro::Attributes.with(:initialize)

    attributes :id, :name, :email

    def persisted?
      !id.nil?
    end
  end
end

module Users::Creation
  require 'uri'
  require 'securerandom'

  class Process < Micro::Case
    attributes :name, :email

    def call!
      normalize_params
        .then(-> data { validate_params(data) })
        .then(-> data { persist(data) })
        .then(-> data { sync_with_crm(data) })
    end

    private

      def normalize_params
        Success result: {
          name: String(name).strip.gsub(/\s+/, ' '),
          email: String(email).downcase.strip
        }
      end

      def validate_params(data)
        name, email = data.values_at(:name, :email)

        validation_errors = []
        validation_errors << "Name can't be blank" if name.blank?
        validation_errors << "Email is invalid" unless email.match?(URI::MailTo::EMAIL_REGEXP)

        return Success() if validation_errors.blank?

        Failure :invalid_attributes, result: {
          errors: OpenStruct.new(full_messages: validation_errors)
        }
      end

      def persist(data)
        user_data = data.slice(:name, :email).merge(id: SecureRandom.uuid)

        user = Users::Entity.new(user_data)

        Success result: { user: user }
      end

      def sync_with_crm(data)
        user = data.fetch(:user)

        if user.persisted?
          # Do some integration stuff...
          crm_id = SecureRandom.uuid

          Success result: { user_id: user.id, crm_id: crm_id }
        else
          Failure :crm_error, result: { message: "User can't be sent to the CRM" }
        end
      end
  end
end

params = {
  "name" => "  Rodrigo  \n  Serradura ",
  "email" => "   RoDRIGo.SERRAdura@gmail.com   "
}

#---------------------------------#
puts "\n-- Success scenario --\n\n"
#---------------------------------#

Users::Creation::Process
  .call(params)
  .on_success do |result|
    user_id, crm_id = result.values_at(:user_id, :crm_id)

    puts " CRM ID: #{crm_id}"
    puts "USER ID: #{user_id}"
  end

#---------------------------------#
puts "\n-- Failure scenario --\n\n"
#---------------------------------#

Users::Creation::Process
  .call(name: '', email: '')
  .on_failure { |(data, _type)| p data[:errors].full_messages }
  .on_failure do |_result, use_case|
    puts "#{use_case.class.name} was the use case responsible for the failure"
  end

# :: example of the output: ::
#
# -- Success scenario --
#
#  CRM ID: f3f189f6-ba6a-40ab-998c-c86773c41c83
# USER ID: c140ffc3-6a7c-4554-972a-c2a0d59f8cb1
#
# -- Failure scenarios --
#
# ["Name can't be blank", "Email is invalid"]
# Users::Creation::ValidateParams was the use case responsible for the failure
