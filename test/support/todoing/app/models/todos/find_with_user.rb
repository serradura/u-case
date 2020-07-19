# frozen_string_literal: true

module Todos
  class FindWithUser < Micro::Case::Strict
    attributes :user, :todo_id

    def call!
      todo = Todo.find_by_id_and_user_id(todo_id, user.id)

      return Success result: { todo: todo } if todo

      Failure(:todo_not_found)
    end
  end
end
