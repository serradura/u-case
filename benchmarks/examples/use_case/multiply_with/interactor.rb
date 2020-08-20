# frozen_string_literal: true

module MultiplyWith
  class Interactor
    include ::Interactor

    def call
      a = context.a
      b = context.b

      if a.is_a?(Numeric) && b.is_a?(Numeric)
        context.number = a * b
      else
        context.fail!(type: :invalid_data)
      end
    end
  end
end
