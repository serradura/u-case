# frozen_string_literal: true

module Micro
  module Service
    class Safe < Service::Base
      def call
        super
      rescue => exception
        raise exception if Error::ByWrongUsage.check(exception)
        Failure(exception)
      end
    end
  end
end
