require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  # NOTE: I used an older version of the Activemodel only to show the compatibility with its older versions.
  gem 'activemodel', '~> 3.2', '>= 3.2.22.5'

  gem 'u-case', '~> 2.6.0', require: 'u-case/with_activemodel_validation'
end

module Users
  class Entity
    include Micro::Attributes.with(:initialize)

    attributes :id, :name, :email

    def persisted?
      !id.nil?
    end
  end

  module Creation
    require 'uri'
    require 'securerandom'

    class ProcessParams < Micro::Case
      attributes :name, :email

      def call!
        Success(name: normalized_name, email: String(email).downcase.strip)
      end

      private def normalized_name
        String(name).strip.gsub(/\s+/, ' ')
      end
    end

    class ValidateParams < Micro::Case
      attributes :name, :email

      validates :name, presence: true
      validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

      def call!
        Success(attributes(:name, :email))
      end
    end

    class Persist < Micro::Case
      attributes :name, :email

      validates :name, :email, kind: String

      def call!
        Success(user: Entity.new(user_data))
      end

      private def user_data
        attributes.merge(id: SecureRandom.uuid)
      end
    end

    class SyncWithCRM < Micro::Case
      attribute :user

      validates :user, kind: Users::Entity

      def call!
        return Success(user_id: user.id, crm_id: sync_with_crm) if user.persisted?

        Failure(:crm_error) { 'User can\'t be sent to the CRM' }
      end

      private def sync_with_crm
        # Do some integration stuff...
        SecureRandom.uuid
      end
    end

    Process = Micro::Case::Flow([
      ProcessParams,
      ValidateParams,
      Persist,
      SyncWithCRM
    ])
  end
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

Users::Creation::ProcessParams
  .call(params)
  .on_success { |value| p value }

#---------------------------------#
puts "\n-- Success scenario --\n\n"
#---------------------------------#

Users::Creation::Process
  .call(params)
  .on_success do |user_id:, crm_id:|
    puts " CRM ID: #{crm_id}"
    puts "USER ID: #{user_id}"
  end

#---------------------------------#
puts "\n-- Failure scenario --\n\n"
#---------------------------------#

Users::Creation::Process
  .call(name: '', email: '')
  .on_failure { |(value, _type)| p value[:errors].full_messages }
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
