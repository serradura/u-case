# frozen_string_literal: true

module Users
  Authenticate = Micro::Cases.flow([
    Find,
    ValidatePassword
  ])
end
