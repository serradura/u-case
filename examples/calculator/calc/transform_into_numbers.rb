class TransformIntoNumbers < Micro::Service::Base
  attributes :a, :b

  def call!
    number_a, number_b = number(a), number(b)

    if number_a && number_b
      Success(a: number(a), b: number(b))
    else
      Failure(:not_a_number)
    end
  end

  private def number(value)
    return value.to_i if value =~ /\A[\-,=]?\d+\z/
    return value.to_f if value =~ /\A[\-,=]?\d+\.\d+\z/
  end
end
