# frozen_string_literal: true

module Users
  class Find < Micro::Case::Strict
    attribute :email

    def call!
      user = User.find_by_email(email)

      return Success { { user: user } } if user

      Failure(:user_not_found)
    end
  end
end
