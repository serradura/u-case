# frozen_string_literal: true

require 'test_helper'

if Gem.loaded_specs.key?('activejob')
  require 'support/active_job_setup'

  module ActiveJobTestUseCases
    class Echo < Micro::Case
      attribute :n, default: 0
      def call!
        Success(result: { value: n * 2 })
      end
    end

    class Boom < Micro::Case
      def call!
        Failure(:boom)
      end
    end

    class WithDsl < Micro::Case
      active_job do
        key 'active_job_test/with_dsl'
        default_options queue: :priority_queue, priority: 7
      end

      attribute :input
      def call!
        Success(result: { v: input })
      end
    end
  end

  class Micro::Case::ActiveJobTest < Minitest::Test
    include ActiveJob::TestHelper

    def setup
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
      ActiveJob::Base.queue_adapter.performed_jobs.clear if ActiveJob::Base.queue_adapter.respond_to?(:performed_jobs)
    end

    # --- basic enqueue ---

    def test_async_enqueues_with_positional_payload
      ActiveJobTestUseCases::Echo.async.call(n: 3)

      jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
      assert_equal(1, jobs.size)

      args = jobs.first['arguments'] || jobs.first[:arguments]
      key = args[0]
      input = args[1]
      raise_on_failure = args[2]

      assert_equal('ActiveJobTestUseCases::Echo', key)
      assert_equal(3, input['n'] || input[:n])
      assert_equal(false, raise_on_failure)
    end

    def test_later_is_alias_of_async
      assert_equal(
        Micro::Case.singleton_method(:async),
        Micro::Case.singleton_method(:later)
      )

      ActiveJobTestUseCases::Echo.later.call(n: 4)

      jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
      assert_equal(1, jobs.size)
    end

    # --- job_options thread through to set(...) ---

    def test_job_options_wait_threads_through
      ActiveJobTestUseCases::Echo.async(job_options: { wait: 30 }).call(n: 1)
      job = ActiveJob::Base.queue_adapter.enqueued_jobs.first

      scheduled = job['scheduled_at'] || job[:scheduled_at]
      refute_nil(scheduled, 'wait: should produce a scheduled_at timestamp')
    end

    def test_job_options_queue_threads_through
      ActiveJobTestUseCases::Echo.async(job_options: { queue: :reports }).call(n: 1)
      job = ActiveJob::Base.queue_adapter.enqueued_jobs.first

      queue = job['queue_name'] || job[:queue]
      assert_equal('reports', queue.to_s)
    end

    def test_job_options_priority_threads_through
      ActiveJobTestUseCases::Echo.async(job_options: { priority: 17 }).call(n: 1)
      job = ActiveJob::Base.queue_adapter.enqueued_jobs.first

      priority = job['priority'] || job[:priority]
      assert_equal(17, priority)
    end

    def test_job_options_unknown_key_raises
      assert_raises(ArgumentError) do
        ActiveJobTestUseCases::Echo.async(job_options: { not_a_key: 1 }).call(n: 1)
      end
    end

    # --- raise_on_failure ---

    def test_raise_on_failure_true_raises_error_at_perform_time
      ActiveJobTestUseCases::Boom.async(raise_on_failure: true).call

      err = assert_raises(Micro::Case::ActiveJob::Error) do
        perform_enqueued_jobs
      end

      assert_match(/failure result/, err.message)
      assert_kind_of(Micro::Case::Result, err.result)
      assert_equal(:boom, err.result.type)
    end

    def test_raise_on_failure_false_silently_returns
      ActiveJobTestUseCases::Boom.async.call

      assert_nothing_raised do
        perform_enqueued_jobs
      end
    end

    def assert_nothing_raised
      yield
    rescue => e
      flunk("expected nothing to raise, got #{e.class}: #{e.message}")
    end

    # --- registry / rename-in-flight ---

    def test_dsl_registers_explicit_key
      assert_equal(
        ActiveJobTestUseCases::WithDsl,
        Micro::Case::ActiveJob.registry.fetch('active_job_test/with_dsl')
      )
    end

    def test_rename_in_flight_resolves_via_registry
      registry = Micro::Case::ActiveJob.registry

      original = Class.new(Micro::Case) do
        attribute :v
        def call!; Success(result: { v: v }); end
      end
      Object.const_set(:RenameOriginal, original)

      original.active_job { key 'rename_test/svc' }

      # Enqueue under the original
      RenameOriginal.async.call(v: 99)
      job = ActiveJob::Base.queue_adapter.enqueued_jobs.last
      args = job['arguments'] || job[:arguments]
      assert_equal('rename_test/svc', args[0])

      # Simulate rename: delete original constant, redefine under a new
      # name, and have the new class take over the same key.
      Object.send(:remove_const, :RenameOriginal)
      registry.instance_variable_get(:@entries).delete('rename_test/svc')

      renamed = Class.new(Micro::Case) do
        attribute :v
        def call!; Success(result: { renamed_v: v }); end
      end
      Object.const_set(:RenameRenamed, renamed)
      renamed.active_job { key 'rename_test/svc' }

      # The key now resolves to the renamed class.
      assert_equal(
        renamed,
        Micro::Case::ActiveJob.resolve_key('rename_test/svc')
      )
    ensure
      Object.send(:remove_const, :RenameOriginal) if Object.const_defined?(:RenameOriginal, false)
      Object.send(:remove_const, :RenameRenamed) if Object.const_defined?(:RenameRenamed, false)
    end

    def test_auto_registration_uses_class_name_as_key
      Micro::Case::ActiveJob.registry.instance_variable_get(:@entries).delete('ActiveJobTestUseCases::Echo')

      ActiveJobTestUseCases::Echo.send(:remove_instance_variable, :@__active_job_job_class) if ActiveJobTestUseCases::Echo.instance_variable_defined?(:@__active_job_job_class)
      ActiveJobTestUseCases::Echo.send(:remove_instance_variable, :@__active_job_key) if ActiveJobTestUseCases::Echo.instance_variable_defined?(:@__active_job_key)
      ActiveJobTestUseCases::Echo.send(:remove_const, :Job) if ActiveJobTestUseCases::Echo.const_defined?(:Job, false)

      ActiveJobTestUseCases::Echo.async.call(n: 1)
      assert_equal(
        'ActiveJobTestUseCases::Echo',
        Micro::Case::ActiveJob.registry.fetch('ActiveJobTestUseCases::Echo').name
      )
    end

    # --- unknown / duplicate keys ---

    def test_unknown_key_raises_with_strict_registry
      Micro::Case.config { |c| c.strict_registry = true }

      err = assert_raises(Micro::Case::ActiveJob::UnknownKey) do
        Micro::Case::ActiveJob.resolve_key('definitely/not/here')
      end
      assert_match(%r{definitely/not/here}, err.message)
    ensure
      Micro::Case.config { |c| c.strict_registry = false }
    end

    def test_unknown_constantizable_key_falls_back_unless_strict
      assert_equal(
        ActiveJobTestUseCases::Echo,
        Micro::Case::ActiveJob.constantize_if_class_like('ActiveJobTestUseCases::Echo')
      )
    end

    def test_duplicate_key_for_different_class_raises
      klass_a = Class.new(Micro::Case) { def call!; Success(); end }
      klass_b = Class.new(Micro::Case) { def call!; Success(); end }
      Object.const_set(:DupKlassA, klass_a)
      Object.const_set(:DupKlassB, klass_b)

      klass_a.active_job { key 'dup_test/svc' }

      assert_raises(ArgumentError) do
        klass_b.active_job { key 'dup_test/svc' }
      end
    ensure
      Object.send(:remove_const, :DupKlassA) if Object.const_defined?(:DupKlassA, false)
      Object.send(:remove_const, :DupKlassB) if Object.const_defined?(:DupKlassB, false)
      Micro::Case::ActiveJob.registry.instance_variable_get(:@entries).delete('dup_test/svc')
    end

    def test_redeclaring_same_key_for_same_class_is_noop
      klass = Class.new(Micro::Case) { def call!; Success(); end }
      Object.const_set(:SameKeyKlass, klass)

      klass.active_job { key 'same_test/svc' }
      assert_nothing_raised { klass.active_job { key 'same_test/svc' } }
    ensure
      Object.send(:remove_const, :SameKeyKlass) if Object.const_defined?(:SameKeyKlass, false)
      Micro::Case::ActiveJob.registry.instance_variable_get(:@entries).delete('same_test/svc')
    end

    # --- DSL ---

    def test_dsl_retry_on_installs_on_per_use_case_subclass
      err_class = Class.new(StandardError)
      klass = Class.new(Micro::Case) { def call!; Success(); end }
      Object.const_set(:DslRetryOnKlass, klass)

      klass.active_job do
        key 'dsl_retry_on/svc'
        retry_on err_class, wait: 1, attempts: 3
      end

      job_class = klass.__active_job_job_class
      # rescue_handlers (older AJ) / rescue_modules — the inspect form
      # exposes the registered exception classes
      assert_includes(job_class.rescue_handlers.flat_map(&:first), err_class.name)
    ensure
      Object.send(:remove_const, :DslRetryOnKlass) if Object.const_defined?(:DslRetryOnKlass, false)
      Micro::Case::ActiveJob.registry.instance_variable_get(:@entries).delete('dsl_retry_on/svc')
    end

    def test_dsl_default_options_merges_with_explicit_job_options
      ActiveJobTestUseCases::WithDsl.async(job_options: { priority: 99 }).call(input: 1)

      job = ActiveJob::Base.queue_adapter.enqueued_jobs.last
      queue = job['queue_name'] || job[:queue]
      priority = job['priority'] || job[:priority]

      # default queue from DSL preserved
      assert_equal('priority_queue', queue.to_s)
      # explicit priority wins over DSL default
      assert_equal(99, priority)
    end

    def test_dsl_around_perform_runs_around_perform
      ran = []
      klass = Class.new(Micro::Case) { def call!; Success(); end }
      Object.const_set(:DslAroundPerformKlass, klass)

      klass.active_job do
        key 'dsl_around/svc'
        around_perform ->(_job, blk) { ran << :before; blk.call; ran << :after }
      end

      klass.async.call
      perform_enqueued_jobs

      assert_equal([:before, :after], ran)
    ensure
      Object.send(:remove_const, :DslAroundPerformKlass) if Object.const_defined?(:DslAroundPerformKlass, false)
      Micro::Case::ActiveJob.registry.instance_variable_get(:@entries).delete('dsl_around/svc')
    end

    def test_dsl_typo_protection_raises_no_method_error
      klass = Class.new(Micro::Case) { def call!; Success(); end }

      err = assert_raises(NoMethodError) do
        klass.active_job do
          retry_no StandardError
        end
      end
      assert_match(/Unknown active_job DSL method: :retry_no/, err.message)
      assert_match(/Valid methods: :key, :retry_on, :discard_on/, err.message)
    end

    # --- inheritance ---

    def test_inheritance_propagates_configuration
      parent = Class.new(Micro::Case) { def call!; Success(); end }
      Object.const_set(:InheritParent, parent)
      parent.active_job { key 'inherit_test/parent'; default_options queue: :p_queue }

      child = Class.new(InheritParent) { def call!; Success(); end }
      Object.const_set(:InheritChild, child)

      assert_same(parent.__active_job_job_class, child.__active_job_job_class)
      assert_equal('inherit_test/parent', child.__active_job_key)
      assert_equal({ queue: :p_queue }, child.__active_job_default_options)
    ensure
      [:InheritParent, :InheritChild].each do |c|
        Object.send(:remove_const, c) if Object.const_defined?(c, false)
      end
      Micro::Case::ActiveJob.registry.instance_variable_get(:@entries).delete('inherit_test/parent')
    end

    def test_subclass_redeclaring_active_job_must_use_fresh_key
      parent = Class.new(Micro::Case) { def call!; Success(); end }
      Object.const_set(:InheritParent2, parent)
      parent.active_job { key 'inherit2_test/parent' }

      child = Class.new(InheritParent2) { def call!; Success(); end }
      Object.const_set(:InheritChild2, child)

      assert_raises(ArgumentError) do
        child.active_job { key 'inherit2_test/parent' }
      end
    ensure
      [:InheritParent2, :InheritChild2].each do |c|
        Object.send(:remove_const, c) if Object.const_defined?(c, false)
      end
      Micro::Case::ActiveJob.registry.instance_variable_get(:@entries).delete('inherit2_test/parent')
    end

    # --- bulk batch ---

    def test_batch_enqueues_each_pair
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear

      Micro::Case::ActiveJob.batch([
        [ActiveJobTestUseCases::Echo, { n: 1 }],
        [ActiveJobTestUseCases::Echo, { n: 2 }, false],
      ])

      jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
      assert_equal(2, jobs.size)
    end

    def test_batch_invalid_pair_raises
      assert_raises(ArgumentError) do
        Micro::Case::ActiveJob.batch([[:not_a_class, {}]])
      end
    end

    # --- to_proc ---

    def test_to_proc_composes_in_blocks
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
      [{ n: 1 }, { n: 2 }, { n: 3 }].each(&ActiveJobTestUseCases::Echo.async)
      assert_equal(3, ActiveJob::Base.queue_adapter.enqueued_jobs.size)
    end
  end
end
