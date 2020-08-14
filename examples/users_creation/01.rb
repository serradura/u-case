require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'activemodel', '~> 6.0'

  gem 'u-case', '~> 3.0.0'
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
      normalized_name = String(name).strip.gsub(/\s+/, ' ')
      normalized_email = String(email).downcase.strip

      validation_errors = []
      validation_errors << "Name can't be blank" if normalized_name.blank?
      validation_errors << "Email is invalid" unless normalized_email.match?(URI::MailTo::EMAIL_REGEXP)

      if validation_errors.present?
        return Failure :invalid_attributes, result: {
          errors: OpenStruct.new(full_messages: validation_errors)
        }
      end

      user = Users::Entity.new(
        id: SecureRandom.uuid,
        name: normalized_name,
        email: normalized_email
      )

      Success result: { user_id: user.id, crm_id: sync_with_crm }
    end

    private def sync_with_crm
      # Do some integration stuff...
      SecureRandom.uuid
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
