# frozen_string_literal: true

module Micro
  class Case
    class Safe < ::Micro::Case
      def call
        super
      rescue => exception
        raise exception if Error::ByWrongUsage.check(exception)

        Failure(exception)
      end
    end
  end
end
