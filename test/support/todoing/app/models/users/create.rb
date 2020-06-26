# frozen_string_literal: true

module Users
  class Create < Micro::Case::Safe
    attributes :email, :password, :password_confirmation

    def call!
      return Failure(:invalid_password) if password != password_confirmation

      user = User.new(attributes(:email, :password))

      return Failure(:validation_error) unless user.save

      Success { { user: user } }
    end
  end
end
