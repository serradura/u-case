# frozen_string_literal: true

module UserTodoList
  class MarkItemAsDone < Micro::Case
    attribute :todo

    flow Users::Authenticate,
        Todos::FindWithUser,
        self.call!

    def call!
      if todo.pending?
        todo.done = true
        todo.save
      end

      Success result: attributes(:todo)
    end
  end
end
