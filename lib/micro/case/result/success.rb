# frozen_string_literal: true

module Micro
  class Case
    class Result
      module Success
        DEFAULT_USE_CASE = -> { ::Micro::Case.send(:new, {}) }

        def self.new(data: {}, type: :ok, use_case: nil)
          instance = ::Micro::Case::Result.new
          instance.__set__(true, data, type, use_case || (@__default ||= DEFAULT_USE_CASE.call))
          instance
        end

        def self.to_yield(**kargs)
          ::Micro::Case::Result::Wrapper.new(new(**kargs))
        end
      end
    end
  end
end
