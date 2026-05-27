# frozen_string_literal: true

require 'test_helper'

if Gem.loaded_specs.key?('activejob')
  require 'support/active_job_setup'

  class Micro::Case::ActiveJobDisableRuntimeChecksTest < Minitest::Test
    i_suck_and_my_tests_are_order_dependent!

    def teardown
      Micro::Case.config do |config|
        config.disable_runtime_checks = false
      end
    end

    # --- key shape ---

    def test_enabled_raises_for_bad_key
      assert_raises(ArgumentError) do
        Micro::Case.check.active_job_key!('')
      end
    end

    def test_disabling_skips_bad_key_check
      Micro::Case.config { |c| c.disable_runtime_checks = true }

      assert_nil(Micro::Case.check.active_job_key!(''))
    end

    # --- retry_on ---

    def test_enabled_raises_for_empty_retry_on
      assert_raises(ArgumentError) do
        Micro::Case.check.active_job_retry_on!([])
      end
    end

    def test_disabling_skips_empty_retry_on_check
      Micro::Case.config { |c| c.disable_runtime_checks = true }

      assert_nil(Micro::Case.check.active_job_retry_on!([]))
    end

    # --- after_transaction_commit ---

    def test_enabled_raises_for_bad_after_transaction_commit_value
      assert_raises(ArgumentError) do
        Micro::Case.check.active_job_after_transaction_commit!(:bogus)
      end
    end

    def test_disabling_skips_after_transaction_commit_check
      Micro::Case.config { |c| c.disable_runtime_checks = true }

      assert_nil(Micro::Case.check.active_job_after_transaction_commit!(:bogus))
    end

    # --- job_options keys ---

    def test_enabled_raises_for_unknown_job_options_key
      assert_raises(ArgumentError) do
        Micro::Case.check.active_job_job_options!({ unknown: 1 })
      end
    end

    def test_disabling_skips_unknown_job_options_key_check
      Micro::Case.config { |c| c.disable_runtime_checks = true }

      assert_nil(Micro::Case.check.active_job_job_options!({ unknown: 1 }))
    end

    # --- batch pairs ---

    def test_enabled_raises_for_bad_batch_pairs
      assert_raises(ArgumentError) do
        Micro::Case.check.active_job_batch_pairs!([[:not_a_class, {}]])
      end
    end

    def test_disabling_skips_batch_pairs_check
      Micro::Case.config { |c| c.disable_runtime_checks = true }

      assert_nil(Micro::Case.check.active_job_batch_pairs!([[:not_a_class, {}]]))
    end

    # --- duplicate key ---

    def test_enabled_raises_for_duplicate_key
      klass_a = Class.new(Micro::Case) { def call!; Success(); end }
      klass_b = Class.new(Micro::Case) { def call!; Success(); end }

      assert_raises(ArgumentError) do
        Micro::Case.check.active_job_registry_no_duplicate!('k', klass_a, klass_b)
      end
    end

    def test_disabling_skips_duplicate_key_check
      Micro::Case.config { |c| c.disable_runtime_checks = true }

      klass_a = Class.new(Micro::Case) { def call!; Success(); end }
      klass_b = Class.new(Micro::Case) { def call!; Success(); end }

      assert_nil(Micro::Case.check.active_job_registry_no_duplicate!('k', klass_a, klass_b))
    end

    # --- same surface area on both modules ---

    def test_disabled_and_enabled_modules_still_expose_the_same_methods
      enabled_methods = (Micro::Case::Check::Enabled.methods - Module.methods).sort
      disabled_methods = (Micro::Case::Check::Disabled.methods - Module.methods).sort

      assert_equal(enabled_methods, disabled_methods)
    end
  end
end
