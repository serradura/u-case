# frozen_string_literal: true

module Users
  class Create < Micro::Case::Safe
    attributes :email, :password, :password_confirmation

    def call!
      return Failure(:invalid_password) if password != password_confirmation

      user = User.new(attributes(:email, :password))

      return Failure(:invalid_attributes) unless user.save

      Success result: { user: user }
    end
  end
end
