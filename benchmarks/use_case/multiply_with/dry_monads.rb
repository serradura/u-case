# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module MultiplyWith
  class DryMonads
    include Dry::Monads[:result]
    include Dry::Monads::Do.for(:call)

    def call(params)
      input = yield normalize(params)

      yield calculate(input['a'], input['b'])
    end

    private

    def normalize(input)
      data = input.map { |key, value| [key.to_s, value] }.to_h

      Success(data)
    end

    def calculate(a, b)
      if a.is_a?(Numeric) && b.is_a?(Numeric)
        Success(a * b)
      else
        Failure(:invalid_data)
      end
    end
  end
end
