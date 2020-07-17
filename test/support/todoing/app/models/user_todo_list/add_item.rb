# frozen_string_literal: true

module UserTodoList
  AddItem = Micro::Cases.flow([
    Users::Authenticate,
    Todos::Create
  ])
end
