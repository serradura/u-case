# frozen_string_literal: true

module Todos
  class Create < Micro::Case::Strict
    attributes :user, :description

    def call!
      todo = Todo.new(user_id: user.id, description: description)

      return Failure(:validation_error) unless todo.save

      Success result: { todo: todo }
    end
  end
end
