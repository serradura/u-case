# frozen_string_literal: true

module Micro
  module Service
    class Result
      module Helpers
        private def Success(arg=nil)
          value, type = block_given? ? [yield, arg] : [arg, nil]
          Result::Success[value: value, type: type]
        end

        private def Failure(arg=nil)
          value, type = block_given? ? [yield, arg] : [arg, nil]
          Result::Failure[value: value, type: type]
        end
      end
    end
  end
end
