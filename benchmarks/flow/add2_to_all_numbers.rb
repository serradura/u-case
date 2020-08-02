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
          Success result: { numbers: numbers.map(&:to_i) }
        else
          Failure result: { numbers: 'must contain only numeric types' }
        end
      end
    end

    class Add2 < Micro::Case
      attribute :numbers

      def call!
        Success result: { numbers: numbers.map { |number| number + 2 } }
      end
    end

    Flow = Micro::Cases.flow([
      ConvertTextToNumbers,
      Add2
    ])

    SafeFlow = Micro::Cases.safe_flow([
      ConvertTextToNumbers,
      Add2
    ])

    module FlowUsingThen
      def self.call(params)
        ConvertTextToNumbers
          .call(params)
          .then(Add2)
      end
    end

    class FlowUsingPrivateMethods < Micro::Case
      attribute :numbers

      def call!
        convert_text_to_numbers
          .then(-> data {  add_2(data[:numbers]) })
      end

      private

        def convert_text_to_numbers
          if numbers.all? { |value| String(value) =~ /\d+/ }
            Success result: { numbers: numbers.map(&:to_i) }
          else
            Failure result: { numbers: 'must contain only numeric types' }
          end
        end

        def add_2(numbers)
          Success result: { numbers: numbers.map { |number| number + 2 } }
        end
    end
  end
end
