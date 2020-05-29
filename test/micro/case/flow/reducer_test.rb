require 'test_helper'
require 'support/todoing/boot'

class Micro::Case::Flow::ReducerTest < Minitest::Test
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
      UserTodoList::AddItem.call(user_id: user.id, password: user_password, description: 'Buy milk')

    assert_success_result(todo_created)

    todo = todo_created.value[:todo]

    refute_nil(todo.id)
    refute_predicate(todo, :new_record?)

    assert_equal(user.id, todo.user_id)

    result =
      UserTodoList::MarkItemAsDone.call(user_id: user.id, password: user_password, todo_id: todo.id)

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
      UserTodoList::AddItem.call(user_id: user.id, password: '', description: 'Buy beer')

    assert_failure_result(result1, type: :wrong_password)

    result2 =
      UserTodoList::AddItem.call(user_id: user.id, password: user_password, description: '')

    assert_failure_result(result2, type: :validation_error)
    assert_instance_of(Todos::Create, result2.use_case)

    assert_equal(1, User.count)
    assert_equal(0, Todo.count)
  end
end
