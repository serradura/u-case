require_relative 'lib/inactive_record'

require_relative 'app/models/user'
require_relative 'app/models/todo'

require_relative 'app/models/users/create'
require_relative 'app/models/users/find'
require_relative 'app/models/users/validate_password'
require_relative 'app/models/users/authenticate'

require_relative 'app/models/todos/create'
require_relative 'app/models/todos/find_with_user'

require_relative 'app/models/user_todo_list/add_item'
require_relative 'app/models/user_todo_list/mark_item_as_done'
