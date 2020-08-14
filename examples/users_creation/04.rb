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
  config.enable_transitions = false
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
  class NormalizeParams < Micro::Case
    attributes :name, :email

    def call!
      normalized_name = String(name).strip.gsub(/\s+/, ' ')
      normalized_email = String(email).downcase.strip

      Success result: { name: normalized_name, email: normalized_email }
    end
  end
end

module Users::Creation
  require 'uri'

  class ValidateParams < Micro::Case
    attributes :name, :email

    validates :name, presence: true
    validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

    def call!
      Success result: attributes(:name, :email)
    end
  end
end

require 'securerandom'

module Users::Creation
  class Persist < Micro::Case
    attributes :name, :email

    validates :name, :email, kind: String

    def call!
      user_data = attributes.merge(id: SecureRandom.uuid)

      Success result: { user: Users::Entity.new(user_data) }
    end
  end
end

module Users::Creation
  class SyncWithCRM < Micro::Case
    attribute :user

    validates :user, kind: Users::Entity

    def call!
      if user.persisted?
        Success result: { user_id: user.id, crm_id: sync_with_crm }
      else
        Failure :crm_error, result: { message: "User can't be sent to the CRM" }
      end
    end

    private def sync_with_crm
      # Do some integration stuff...
      SecureRandom.uuid
    end
  end
end

module Users::Creation
  Process = Micro::Cases.flow([
    NormalizeParams,
    ValidateParams,
    Persist,
    SyncWithCRM
  ])
end

params = {
  "name" => "  Rodrigo  \n  Serradura ",
  "email" => "   RoDRIGo.SERRAdura@gmail.com   "
}

#--------------------------------------#
puts "\n-- Parameters processing --\n\n"
#--------------------------------------#

print 'Before: '
p params

print ' After: '

Users::Creation::NormalizeParams
  .call(params)
  .on_success { |result| p result.data }

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
# -- Parameters processing --
#
# Before: {"name"=>"  Rodrigo  \n  Serradura ", "email"=>"   RoDRIGo.SERRAdura@gmail.com   "}
#  After: {:name=>"Rodrigo Serradura", :email=>"rodrigo.serradura@gmail.com"}
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
