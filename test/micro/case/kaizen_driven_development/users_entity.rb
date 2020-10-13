# frozen_string_literal: true

class Micro::Case::KaizenDrivenDevelopment
  module Users
    class Entity
      include Micro::Attributes.with(:initialize)

      attributes :id, :name, :email

      def persisted?
        !id.nil?
      end
    end
  end
end
