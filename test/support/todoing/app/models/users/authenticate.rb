# frozen_string_literal: true

module Users
  Authenticate = Micro::Case::Flow([
    Find,
    ValidatePassword
  ])
end
