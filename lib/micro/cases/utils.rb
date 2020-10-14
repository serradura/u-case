# frozen_string_literal: true

module Micro
  module Cases

    module Utils
      def self.map_use_cases(args)
        collection = args.is_a?(Array) && args.size == 1 ? args[0] : args

        Array(collection).each_with_object([]) do |arg, memo|
          if arg.is_a?(Flow)
            arg.use_cases.each { |use_case| memo << use_case }
          else
            memo << arg
          end
        end
      end
    end

  end
end
