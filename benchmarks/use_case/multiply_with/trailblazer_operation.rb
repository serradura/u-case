# frozen_string_literal: true

module MultiplyWith
  class Trailblazer < ::Trailblazer::Operation
    step :calculate

    private

      def calculate(options, a:, b:)
        if a.is_a?(Numeric) && b.is_a?(Numeric)
          options[:number] = a * b
        end
      end
  end
end
