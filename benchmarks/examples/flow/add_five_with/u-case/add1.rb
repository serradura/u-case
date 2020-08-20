# frozen_string_literal: true

class Add1 < Micro::Case
  attribute :number

  def call!
    Success result: number + 1
  end
end
