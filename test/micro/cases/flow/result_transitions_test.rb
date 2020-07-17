require 'test_helper'
require 'support/todoing/boot'

class Micro::Cases::Flow::ResultTransitionsTest < Minitest::Test
  def setup
    [User, Todo].each(&:delete_all)
  end

  def test_the_todo_creation_and_marking_its_as_done
    user_password = '123456'

    user_created =
      Users::Create.call(email: 'rodrigo@test.com', password: user_password, password_confirmation: user_password)

    assert_success_result(user_created)

    user = user_created.value[:user]

    refute_nil(user.id)
    refute_predicate(user, :new_record?)

    user_authenticated =
      Users::Authenticate.call(email: 'rodrigo@test.com', password: user_password)

    assert_success_result(user_authenticated)

    todo_created =
      UserTodoList::AddItem.call(email: 'rodrigo@test.com', password: user_password, description: 'Buy milk')

    assert_success_result(todo_created)

    todo = todo_created.value[:todo]

    refute_nil(todo.id)
    refute_predicate(todo, :new_record?)

    assert_equal(user.id, todo.user_id)

    result =
      UserTodoList::MarkItemAsDone.call(email:'rodrigo@test.com', password: user_password, todo_id: todo.id)

    todo_updated = result.value[:todo]

    assert_equal(todo.id, todo_updated.id)
    assert_predicate(todo_updated, :done?)

    assert_equal(1, User.count)
    assert_equal(1, Todo.count)
  end

  def test_a_todo_creation_failure
    user_password = '123456'

    user_created =
      Users::Create.call(email: 'rodrigo@test.com', password: user_password, password_confirmation: user_password)

    assert_success_result(user_created)

    result1 =
      UserTodoList::AddItem.call(email:'rodrigo@test.com', password: '', description: 'Buy beer')

    assert_failure_result(result1, type: :wrong_password)

    result2 =
      UserTodoList::AddItem.call(email:'rodrigo@test.com', password: user_password, description: '')

    assert_failure_result(result2, type: :validation_error)
    assert_instance_of(Todos::Create, result2.use_case)

    assert_equal(1, User.count)
    assert_equal(0, Todo.count)
  end

  def test_the_result_transitions_after_creating_a_todo
    user_password = '123456'

    Users::Create.call(email: 'rodrigo@test.com', password: user_password, password_confirmation: user_password)

    todo_created =
      UserTodoList::AddItem.call(email:'rodrigo@test.com', password: user_password, description: 'Buy milk')

    result_transitions = todo_created.transitions

    assert_equal(3, result_transitions.size)

    # --------------
    # transitions[0]
    # --------------

    first_transition = result_transitions[0]

    # transitions[0][:use_case]
    first_transition_use_case = first_transition[:use_case]

    # transitions[0][:use_case][:class]
    assert_equal(Users::Find, first_transition_use_case[:class])

    # transitions[0][:use_case][:attributes]
    assert_equal([:email], first_transition_use_case[:attributes].keys)

    assert_instance_of(String, first_transition_use_case[:attributes][:email])

    # transitions[0][:success]
    assert(first_transition.include?(:success))

    first_transition_result = first_transition[:success]

    # transitions[0][:success][:type]
    assert_equal(:ok, first_transition_result[:type])

    # transitions[0][:success][:value]
    assert_equal([:user], first_transition_result[:value].keys)

    assert_instance_of(User, first_transition_result[:value][:user])

    # transitions[0][:accessible_attributes]
    assert_equal([:email, :password, :description], first_transition[:accessible_attributes])

    # --------------
    # transitions[1]
    # --------------

    second_transition = result_transitions[1]

    # transitions[1][:use_case]
    second_transition_use_case = second_transition[:use_case]

    # transitions[1][:use_case][:class]
    assert_equal(Users::ValidatePassword, second_transition_use_case[:class])

    # transitions[1][:use_case][:attributes]
    assert_equal([:user, :password], second_transition_use_case[:attributes].keys)

    assert_instance_of(User, second_transition_use_case[:attributes][:user])
    assert_instance_of(String, second_transition_use_case[:attributes][:password])

    # transitions[1][:success]
    assert(second_transition.include?(:success))

    second_transition_result = second_transition[:success]

    # transitions[1][:success][:type]
    assert_equal(:ok, second_transition_result[:type])

    # transitions[1][:success][:value]
    assert_equal([:user], second_transition_result[:value].keys)

    assert_instance_of(User, second_transition_result[:value][:user])

    # transitions[1][:accessible_attributes]
    assert_equal([:email, :password, :description, :user], second_transition[:accessible_attributes])

    # --------------
    # transitions[2]
    # --------------

    third_transition = result_transitions[2]

    # transitions[2][:use_case]
    third_transition_use_case = third_transition[:use_case]

    # transitions[2][:use_case][:class]
    assert_equal(Todos::Create, third_transition_use_case[:class])

    # transitions[2][:use_case][:attributes]
    assert_equal([:user, :description], third_transition_use_case[:attributes].keys)

    assert_instance_of(User, third_transition_use_case[:attributes][:user])

    assert_instance_of(String, third_transition_use_case[:attributes][:description])
    assert_equal('Buy milk', third_transition_use_case[:attributes][:description])

    # transitions[2][:success]
    assert(third_transition.include?(:success))

    third_transition_result = third_transition[:success]

    # transitions[2][:success][:type]
    assert_equal(:ok, third_transition_result[:type])

    # transitions[2][:success][:value]
    assert_equal([:todo], third_transition_result[:value].keys)

    assert_instance_of(Todo, third_transition_result[:value][:todo])
    assert_equal(
      third_transition_use_case[:attributes][:description],
      third_transition_result[:value][:todo].description
    )

    # transitions[2][:accessible_attributes]
    assert_equal([:email, :password, :description, :user], third_transition[:accessible_attributes])
  end
end
