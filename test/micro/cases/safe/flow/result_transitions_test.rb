require 'test_helper'

class Micro::Cases::Safe::Flow::ResultTransitionsTest < Minitest::Test
  require 'digest'
  require 'securerandom'

  class User < InactiveRecord::Base
    attr_reader :password_hash
    attr_accessor :name

    def initialize(options = {})
      @name = options[:name]
      @password = options[:password]
    end

    def invalid?
      name.empty? || @password.empty?
    end

    def save
      return false if invalid?

      self.name = name

      save_new_record do
        @password_hash = Digest::SHA256.hexdigest(@password)
      end
    end

    def wrong_password?(value)
      password_hash != Digest::SHA256.hexdigest(value)
    end
  end

  class Todo < InactiveRecord::Base
    attr_accessor :description, :done, :user_id

    def self.find_by_id_and_user_id(id, user_id)
      all.find { |todo| todo.id == id && todo.user_id && user_id }
    end

    def initialize(options = {})
      @user_id = options[:user_id]
      @description = options[:description]
    end

    def invalid?
      description.empty? || user_id.empty?
    end

    def save
      return false if invalid?

      self.description = description

      save_new_record { @done = done? }
    end

    def pending?; !done; end

    def done?; !pending?; end
  end

  module Users
    class Create < Micro::Case::Strict::Safe
      attributes :name, :password, :password_confirmation

      def call!
        return Failure(:invalid_password) if password != password_confirmation

        user = User.new(attributes(:name, :password))

        return Failure(:validation_error) unless user.save

        Success result: { user: user }
      end
    end

    class Fetch < Micro::Case::Strict::Safe
      attribute :user_id

      def call!
        user = User.find_by_id(user_id)

        return Success result: { user: user } if user

        Failure(:user_not_found)
      end
    end

    class CheckPassword < Micro::Case::Strict::Safe
      attributes :user, :password

      def call!
        return Failure(:user_must_be_persisted) if user.new_record?
        return Failure(:wrong_password) if user.wrong_password?(password)

        return Success result: attributes(:user)
      end
    end

    Authenticate = Micro::Cases.safe_flow([
      Fetch,
      CheckPassword
    ])
  end

  module Todos
    class Create < Micro::Case::Strict::Safe
      attributes :user, :description

      def call!
        todo = Todo.new(user_id: user.id, description: description)

        return Failure(:validation_error) unless todo.save

        Success result: { todo: todo }
      end
    end

    class FetchByUser < Micro::Case::Strict::Safe
      attributes :user, :todo_id

      def call!
        todo = Todo.find_by_id_and_user_id(todo_id, user.id)

        return Success result: { todo: todo } if todo

        Failure(:todo_not_found)
      end
    end

    class SetToDone < Micro::Case::Strict::Safe
      attribute :todo

      def call!
        if todo.pending?
          todo.done = true
          todo.save
        end

        return Success result: attributes(:todo)
      end
    end
  end

  module UserTodos
    Create = Micro::Cases.safe_flow([Users::Authenticate, Todos::Create])

    class MarkAsDone < Micro::Case
      flow Users::Authenticate,
        Todos::FetchByUser,
        Todos::SetToDone
    end
  end

  def setup
    [User, Todo].each(&:delete_all)
  end

  def test_the_todo_creation_and_its_marking_as_done
    user_password = '123456'

    user_created =
      Users::Create.call(name: 'Rodrigo', password: user_password, password_confirmation: user_password)

    assert_success_result(user_created)

    user = user_created.value[:user]

    refute_nil(user.id)
    refute_predicate(user, :new_record?)

    todo_created =
      UserTodos::Create.call(user_id: user.id, password: user_password, description: 'Buy milk')

    assert_success_result(todo_created)

    todo = todo_created.value[:todo]

    refute_nil(todo.id)
    refute_predicate(todo, :new_record?)

    assert_equal(user.id, todo.user_id)

    result =
      UserTodos::MarkAsDone.call(user_id: user.id, password: user_password, todo_id: todo.id)

    todo_updated = result.value[:todo]

    assert_equal(todo.id, todo_updated.id)
    assert_predicate(todo_updated, :done?)

    assert_equal(1, User.count)
    assert_equal(1, Todo.count)
  end

  def test_the_some_todo_creation_failures
    user_password = '123456'

    user_created =
      Users::Create.call(name: 'Rodrigo', password: user_password, password_confirmation: user_password)

    assert_success_result(user_created)

    user = user_created.value[:user]

    result1 =
      UserTodos::Create.call(user_id: user.id, password: '', description: 'Buy beer')

    assert_failure_result(result1, type: :wrong_password)

    result2 =
      UserTodos::Create.call(user_id: user.id, password: user_password, description: '')

    assert_failure_result(result2, type: :validation_error)
    assert_instance_of(Todos::Create, result2.use_case)

    assert_equal(1, User.count)
    assert_equal(0, Todo.count)
  end
end
