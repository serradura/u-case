class Operation < Micro::Case
  attributes :a, :b

  private def operation_info(operation_result)
    attributes(:a, :operator, :b)
      .merge(result: operation_result)
  end

  class Add < Operation
    attribute :operator, '+'

    def call!
      Success result: operation_info(a + b)
    end
  end

  class Subtract < Operation
    attribute :operator, '-'

    def call!
      Success result: operation_info(a - b)
    end
  end

  class Multiply < Operation
    attribute :operator, 'x'

    def call!
      Success result: operation_info(a * b)
    end
  end

  class Divide < Operation
    attribute :operator, '/'

    def call!
      Success result: operation_info(a / b)
    end
  end
end
