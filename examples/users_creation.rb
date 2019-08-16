require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  # NOTE: I used an older version of the Activemodel only to show the compatibility with its older versions.
  gem 'activemodel', '~> 3.2', '>= 3.2.22.5'
  gem 'u-service', '~> 0.12.0'
end

require 'micro/service/with_validation'

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

    class ProcessParams < Micro::Service::Base
      attributes :name, :email

      def call!
        Success(name: normalized_name, email: String(email).downcase.strip)
      end

      private def normalized_name
        String(name).strip.gsub(/\s+/, ' ')
      end
    end

    class ValidateParams < Micro::Service::WithValidation
      attributes :name, :email

      validates :name, presence: true
      validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

      def call!
        Success(attributes(:name, :email))
      end
    end

    class Persist < Micro::Service::Base
      attributes :name, :email

      def call!
        Success(user: Entity.new(user_data))
      end

      private def user_data
        attributes.merge(id: SecureRandom.uuid)
      end
    end

    class SendToCRM < Micro::Service::Base
      attribute :user

      def call!
        return Success(user_id: user.id, crm_id: send_to_crm) if user.persisted?

        Failure(:crm_error) { 'User can\'t be sent to the CRM' }
      end

      private def send_to_crm
        # Do some integration stuff...
        SecureRandom.uuid
      end
    end

    Process = ProcessParams >> ValidateParams >> Persist >> SendToCRM
  end
end

require 'pp'

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
Users::Creation::ProcessParams.call(params).on_success { |value| p value }

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
  .on_failure { |errors:| p errors.full_messages }


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
