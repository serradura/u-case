# frozen_string_literal: true

module Steps
  class ConvertToNumbers < Micro::Case::Base
    attribute :numbers

    def call!
      if !numbers.nil? && numbers.all? { |value| String(value) =~ /\d+/ }
        Success(numbers: numbers.map(&:to_i))
      else
        Failure('numbers must contain only numeric types')
      end
    end
  end

  class Add2 < Micro::Case::Strict
    attribute :numbers

    def call!
      Success(numbers: numbers.map { |number| number + 2 })
    end
  end

  class Double < Micro::Case::Strict
    attribute :numbers

    def call!
      Success(numbers: numbers.map { |number| number * 2 })
    end
  end

  class Square < Micro::Case::Strict
    attribute :numbers

    def call!
      Success(numbers: numbers.map { |number| number * number })
    end
  end
end
