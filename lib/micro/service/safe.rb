# frozen_string_literal: true

module Micro
  module Service
    class Safe < Service::Base
      def call
        begin
          super
        rescue => exception
          raise exception if exception.is_a?(Micro::Service::Base::UnexpectedResult)

          Failure(:exception) { exception }
        end
      end
    end
  end
end
