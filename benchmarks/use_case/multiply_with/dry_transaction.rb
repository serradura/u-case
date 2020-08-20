# frozen_string_literal: true

module MultiplyWith
  class DryTransaction
    include Dry::Transaction

    step :normalize
    step :calculate

    private

    def normalize(input)
      data = input.map { |key, value| [key.to_s, value] }.to_h

      Success(data)
    end

    def calculate(input)
      a = input['a']
      b = input['b']

      if a.is_a?(Numeric) && b.is_a?(Numeric)
        Success(a * b)
      else
        Failure(:invalid_data)
      end
    end
  end
end
