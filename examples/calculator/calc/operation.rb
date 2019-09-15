class Operation < Micro::Case::Base
  attributes :a, :b

  private def result_of(operation_result)
    attributes(:a, :operator, :b).merge(result: operation_result)
  end

  class Add < Operation
    attribute :operator, '+'

    def call!
      Success(result_of(a + b))
    end
  end

  class Subtract < Operation
    attribute :operator, '-'

    def call!
      Success(result_of(a - b))
    end
  end

  class Multiply < Operation
    attribute :operator, 'x'

    def call!
      Success(result_of(a * b))
    end
  end

  class Divide < Operation
    attribute :operator, '/'

    def call!
      Success(result_of(a / b))
    end
  end
end
