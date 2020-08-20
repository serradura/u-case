# frozen_string_literal: true

class ConvertTextToNumber < Micro::Case
  attribute :text

  def call!
    return Success(result: text.to_i) if text =~ /\d+/

    Failure result: { text: 'must be an integer value' }
  end
end
