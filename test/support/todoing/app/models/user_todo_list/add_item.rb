# frozen_string_literal: true

module UserTodoList
  AddItem = Micro::Case::Flow([
    Users::Authenticate,
    Todos::Create
  ])
end
