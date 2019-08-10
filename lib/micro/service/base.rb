# frozen_string_literal: true

module Micro
  module Service
    class Base
      include Micro::Attributes.without(:strict_initialize)
      include Result::Helpers

      INVALID_RESULT = '#call! must return a Micro::Service::Result instance'.freeze

      def self.>>(service)
        Micro::Service::Pipeline[self, service]
      end

      def self.call(options = {})
        new(options).call
      end

      def call!
        raise NotImplementedError
      end

      def call
        result = call!
        return result if result.is_a?(Service::Result)
        raise TypeError, self.class.name + INVALID_RESULT
      end
    end
  end
end
