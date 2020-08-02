require 'dry/monads'
require 'dry/monads/do'

module Multiply
  class WithInteractor
    include Interactor

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

  class WithMicroCase < Micro::Case
    attributes :a, :b

    def call!
      if a.is_a?(Numeric) && b.is_a?(Numeric)
        Success(result: { number: a * b })
      else
        Failure(:invalid_data)
      end
    end
  end

  class WithMicroCaseStrict < Micro::Case::Strict
    attributes :a, :b

    def call!
      if a.is_a?(Numeric) && b.is_a?(Numeric)
        Success(result: { number: a * b })
      else
        Failure(:invalid_data)
      end
    end
  end

  class WithMicroCaseSafe < Micro::Case::Safe
    attributes :a, :b

    def call!
      if a.is_a?(Numeric) && b.is_a?(Numeric)
        Success(result: { number: a * b })
      else
        Failure(:invalid_data)
      end
    end
  end

  class WithDryTransaction
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

  class WithDryMonads
    include Dry::Monads[:result]
    include Dry::Monads::Do.for(:call)

    def call(params)
      input = yield normalize(params)
      number = yield calculate(input['a'], input['b'])

      Success(number)
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

  class WithTrailblazerOperation < Trailblazer::Operation
    step :normalize
    step :calculate

    private

    def normalize(options, params:, **)
      input = params.map { |key, value| [key.to_s, value] }.to_h

      options[:a] = params['a']
      options[:b] = params['b']
    end

    def calculate(options, a:, b:, **)
      if a.is_a?(Numeric) && b.is_a?(Numeric)
        options[:number] = a * b
      end
    end
  end
end
