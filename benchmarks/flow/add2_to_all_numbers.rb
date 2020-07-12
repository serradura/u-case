module Add2ToAllNumbers
  module WithInteractor
    class ConvertTextToNumbers
      include Interactor

      def call
        numbers = context.numbers

        if numbers.all? { |value| String(value) =~ /\d+/ }
          context.numbers = numbers.map(&:to_i)
        else
          context.fail! numbers: 'must contain only numeric types'
        end
      end
    end

    class Add2
      include Interactor

      def call
        numbers = context.numbers

        context.numbers = numbers.map { |number| number + 2 }
      end
    end

    class Organizer
      include Interactor::Organizer

      organize ConvertTextToNumbers, Add2
    end
  end

  module WithMicroCase
    class ConvertTextToNumbers < Micro::Case
      attribute :numbers

      def call!
        if numbers.all? { |value| String(value) =~ /\d+/ }
          Success(numbers: numbers.map(&:to_i))
        else
          Failure(numbers: 'must contain only numeric types')
        end
      end
    end

    class Add2 < Micro::Case
      attribute :numbers

      def call!
        Success(numbers: numbers.map { |number| number + 2 })
      end
    end

    Flow = Micro::Case::Flow([
      ConvertTextToNumbers, Add2
    ])

    SafeFlow = Micro::Case::Safe::Flow([
      ConvertTextToNumbers, Add2
    ])
  end
end
