require 'test_helper'

if ENV.fetch('ACTIVERECORD_VERSION', '6.2') <= '6.1.0'
  require 'active_record'
  require 'sqlite3'

  ActiveRecord::Base.establish_connection(
    host: 'localhost',
    adapter: 'sqlite3',
    database: ':memory:'
  )

  ActiveRecord::Schema.define do
    create_table :users do |t|
      t.column :name, :string
    end

    create_table :user_profiles do |t|
      t.column :info, :string

      t.integer :user_id, null: false,
                          index: { name: 'index_user_profiles_on_user_id' },
                          foreign_key: {
                            references: 'users',
                            name: 'fk_test_9ad9d5a760',
                            on_update: :no_action,
                            on_delete: :no_action
                          }
    end
  end

  class Micro::Case::TransactionActiverecordTest < Minitest::Test
    class User < ActiveRecord::Base
      has_one :user_profile
    end

    class UserProfile < ActiveRecord::Base
      belongs_to :user
    end

    class CreateUser < Micro::Case
      attribute :name, validates: { presence: true }

      def call!
        user = User.create(name: name)

        Success result: { user: user }
      end
    end

    class CreateUserProfile < Micro::Case
      attribute :user, validates: { kind: User }
      attribute :info, validates: { presence: true }

      def call!
        profile = UserProfile.create(info: info, user_id: user.id)

        Success result: { user: user, profile: profile }
      end
    end

    class CreateUserWithAProfile1 < Micro::Case
      def call!
        transaction {
          call(CreateUser)
            .then(CreateUserProfile)
        }
      end
    end

    class CreateUserWithAProfile2 < Micro::Case
      def call!
        transaction {
          call(CreateUser)
        }.then(CreateUserProfile)
      end
    end

    def teardown
      [UserProfile, User].each(&:delete_all)
    end

    def test_a_successful_result_after_a_db_transaction
      [CreateUserWithAProfile1, CreateUserWithAProfile2].each do |use_case|
        result = use_case.call(name: 'Serradura', info: 'Foo Bar...')

        assert_predicate(result, :success?)

        user, profile = result.values_at(:user, :profile)

        assert_predicate(user, :persisted?)
        assert_predicate(profile, :persisted?)

        assert_equal(user.id, profile.user_id)

        assert_equal('Serradura', user.name)
        assert_equal('Foo Bar...', profile.info)
      end
    end

    def test_a_failure_result_after_a_db_transaction
      result1 = CreateUserWithAProfile1.call(name: 'Serradura', info: '')

      assert_predicate(result1, :failure?)

      assert_equal(0, User.count)
      assert_equal(0, UserProfile.count)

      # --

      result2 = CreateUserWithAProfile2.call(name: 'Rodrigo', info: '')

      assert_predicate(result2, :failure?)

      assert_equal(1, User.count)
      assert_equal(0, UserProfile.count)

      assert_equal('Rodrigo', User.first.name)
    end
  end

end
