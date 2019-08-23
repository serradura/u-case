# frozen_string_literal: true

module Micro
  module Service
    class Safe < Service::Base
      def self.failure_type(arg, type)
        return :exception if type == :error && arg.is_a?(Exception)
        type
      end

      def call
        super
      rescue => exception
        raise exception if Error::ByWrongUsage.check(exception)
        Failure(exception)
      end

      private

        def Failure(arg = :error)
          value = block_given? ? yield : arg
          type = self.class.failure_type(value, block_given? ? arg : :error)
          __get_result__.__set__(false, value, type, self)
        end
    end
  end
end
