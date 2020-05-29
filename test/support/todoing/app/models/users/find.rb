# frozen_string_literal: true

module Users
  class Find < Micro::Case::Strict
    attribute :user_id

    def call!
      user = User.find_by_id(user_id)

      return Success { { user: user } } if user

      Failure(:user_not_found)
    end
  end
end
