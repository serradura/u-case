# frozen_string_literal: true

unless defined?(::ActiveJob::Base)
  raise LoadError,
    "micro/case/active_job requires ActiveJob to be loaded first. " \
    "Add `activejob` to your Gemfile and `require 'active_job'` before this file " \
    "(Rails apps get this automatically)."
end

require 'micro/case'

module Micro
  class Case
    class ActiveJob < ::ActiveJob::Base
      class Error < StandardError
        attr_reader :result

        def initialize(result_or_message)
          if result_or_message.is_a?(::Micro::Case::Result)
            @result = result_or_message
            super("Micro::Case returned a failure result (type=#{result_or_message.type.inspect})")
          else
            super(result_or_message.to_s)
          end
        end
      end

      class UnknownKey < StandardError
        attr_reader :key

        def initialize(key)
          @key = key
          super(
            "Micro::Case::ActiveJob::Registry has no entry for #{key.inspect}. " \
            "Declare it on the (possibly renamed) class via `active_job do; key #{key.inspect}; end`."
          )
        end
      end

      class Registry
        def initialize
          @mutex = Mutex.new
          @entries = {}
        end

        def register(key, klass)
          @mutex.synchronize do
            ::Micro::Case.check.active_job_registry_no_duplicate!(key, @entries[key], klass)
            @entries[key] = klass
          end
        end

        def fetch(key)
          @mutex.synchronize { @entries[key] }
        end

        def key_for(klass)
          @mutex.synchronize do
            @entries.each { |k, v| return k if v == klass }
            nil
          end
        end

        def all
          @mutex.synchronize { @entries.dup }
        end

        def clear
          @mutex.synchronize { @entries.clear }
        end
      end

      class << self
        def registry
          @registry ||= Registry.new
        end

        def resolve_key(key)
          klass = registry.fetch(key)
          return klass if klass

          unless ::Micro::Case::Config.instance.strict_registry
            candidate = constantize_if_class_like(key)
            return candidate if candidate.is_a?(Class) && candidate < ::Micro::Case
          end

          raise UnknownKey.new(key)
        end

        def constantize_if_class_like(key)
          return nil unless key.is_a?(String)
          return nil if key.empty?

          first = key[0]
          return nil unless key.include?('::') || (first && first == first.upcase && first =~ /[A-Z]/)

          key.split('::').inject(Object) do |const, part|
            return nil unless const.const_defined?(part, false)
            const.const_get(part, false)
          end
        rescue NameError
          nil
        end

        WARNINGS_SHOWN = {}
        WARNINGS_MUTEX = Mutex.new

        def warn_once(feature, requirement)
          WARNINGS_MUTEX.synchronize do
            return if WARNINGS_SHOWN[feature]
            WARNINGS_SHOWN[feature] = true
          end
          Kernel.warn(
            "[Micro::Case::ActiveJob] `#{feature}` requires #{requirement}; " \
            "ignored on this Rails/ActiveJob version."
          )
        end

        # Builds a per-use-case ActiveJob subclass and names it as
        # `<UseCase>::Job` so ActiveJob can serialize it across enqueue
        # and dequeue. Anonymous job classes don't survive the wire.
        def build_named_job_class(use_case_class, parent_job)
          parent = parent_job || ::Micro::Case::ActiveJob
          job_class = Class.new(parent)

          if use_case_class.const_defined?(:Job, false)
            existing = use_case_class.const_get(:Job, false)
            if existing.is_a?(Class) && existing < ::Micro::Case::ActiveJob
              # Re-declaration (file reload, etc.): reuse the existing
              # named constant by remaking the class under that name.
              use_case_class.send(:remove_const, :Job)
            end
          end

          use_case_class.const_set(:Job, job_class)
          job_class
        end

        def batch(pairs)
          ::Micro::Case.check.active_job_batch_pairs!(pairs)

          jobs = pairs.map do |pair|
            klass = pair[0]
            input = pair[1]
            raise_on_failure = pair.size == 3 ? pair[2] : false

            ::Micro::Case::ActiveJob::Caller.ensure_registered!(klass)
            job_class = klass.__active_job_job_class
            key = klass.__active_job_key

            job_class.new(key, input, raise_on_failure)
          end

          if ::ActiveJob.respond_to?(:perform_all_later)
            ::ActiveJob.perform_all_later(jobs)
          else
            jobs.each(&:enqueue)
          end

          jobs
        end
      end

      queue_as :default

      def perform(key, input, raise_on_failure)
        klass = ::Micro::Case::ActiveJob.resolve_key(key)
        result = klass.call(input)

        if raise_on_failure && result.failure?
          raise ::Micro::Case::ActiveJob::Error.new(result)
        end

        result
      end

      class DSL
        DSL_METHODS = %i[
          key retry_on discard_on after_discard
          default_options around_perform after_transaction_commit
        ].freeze

        def initialize(use_case_class)
          @use_case_class = use_case_class
          @job_class = build_job_class
          @key = nil
          @default_options = {}
        end

        def key(string)
          ::Micro::Case.check.active_job_key!(string)
          @key = string
        end

        def retry_on(*exceptions, **opts, &block)
          ::Micro::Case.check.active_job_retry_on!(exceptions)
          @job_class.retry_on(*exceptions, **opts, &block)
        end

        def discard_on(*exceptions, &block)
          ::Micro::Case.check.active_job_discard_on!(exceptions)
          @job_class.discard_on(*exceptions, &block)
        end

        def after_discard(callable = nil, &block)
          handler = block || callable
          ::Micro::Case.check.active_job_after_discard!(handler)

          if @job_class.respond_to?(:after_discard)
            @job_class.after_discard { |job, error| handler.call(job, error) }
          else
            ::Micro::Case::ActiveJob.warn_once(:after_discard, 'Rails 7.1+')
          end
        end

        def default_options(hash)
          ::Micro::Case.check.active_job_default_options!(hash)
          @default_options = hash
        end

        def around_perform(callable = nil, &block)
          handler = block || callable
          ::Micro::Case.check.active_job_around_perform!(handler)
          @job_class.around_perform { |job, blk| handler.call(job, blk) }
        end

        def after_transaction_commit(setting)
          ::Micro::Case.check.active_job_after_transaction_commit!(setting)

          if @job_class.respond_to?(:enqueue_after_transaction_commit=)
            @job_class.enqueue_after_transaction_commit = setting
          else
            ::Micro::Case::ActiveJob.warn_once(:after_transaction_commit, 'Rails 7.2+')
          end
        end

        def method_missing(name, *_args, **_kwargs, &_block)
          raise NoMethodError,
            "Unknown active_job DSL method: #{name.inspect}. " \
            "Valid methods: #{DSL_METHODS.map(&:inspect).join(', ')}."
        end

        def respond_to_missing?(name, include_private = false)
          DSL_METHODS.include?(name) || super
        end

        def __finalize!
          final_key = @key || @use_case_class.name
          ::Micro::Case::ActiveJob.registry.register(final_key, @use_case_class)

          @use_case_class.instance_variable_set(:@__active_job_job_class, @job_class)
          @use_case_class.instance_variable_set(:@__active_job_key, final_key)
          @use_case_class.instance_variable_set(:@__active_job_default_options, @default_options)
        end

        private

        def build_job_class
          parent = @use_case_class.superclass
          parent_job =
            if parent.is_a?(Class) && parent < ::Micro::Case
              parent.instance_variable_get(:@__active_job_job_class)
            end

          ::Micro::Case::ActiveJob.build_named_job_class(@use_case_class, parent_job)
        end
      end

      class Caller
        def initialize(use_case_class, job_options:, raise_on_failure:)
          @use_case_class = use_case_class
          @job_options = job_options
          @raise_on_failure = raise_on_failure
        end

        def call(input = ::Kind::Empty::HASH)
          self.class.ensure_registered!(@use_case_class)

          job_class = @use_case_class.__active_job_job_class
          key = @use_case_class.__active_job_key
          defaults = @use_case_class.__active_job_default_options || {}
          merged = defaults.merge(@job_options)

          if merged.empty?
            job_class.perform_later(key, input, @raise_on_failure)
          else
            job_class.set(merged).perform_later(key, input, @raise_on_failure)
          end
        end

        def to_proc
          method(:call).to_proc
        end

        REGISTRATION_MUTEX = Mutex.new

        def self.ensure_registered!(klass)
          return if klass.instance_variable_get(:@__active_job_job_class)

          REGISTRATION_MUTEX.synchronize do
            return if klass.instance_variable_get(:@__active_job_job_class)

            parent = klass.superclass
            parent_job =
              if parent.is_a?(Class) && parent < ::Micro::Case
                parent.instance_variable_get(:@__active_job_job_class)
              end

            job_class = ::Micro::Case::ActiveJob.build_named_job_class(klass, parent_job)
            fallback_key = klass.name

            ::Micro::Case::ActiveJob.registry.register(fallback_key, klass)
            klass.instance_variable_set(:@__active_job_job_class, job_class)
            klass.instance_variable_set(:@__active_job_key, fallback_key)
            klass.instance_variable_set(:@__active_job_default_options, {})
          end
        end
      end
    end

    # Re-open Micro::Case to add the new class-level surface.
    class << self
      def active_job(&block)
        dsl = ::Micro::Case::ActiveJob::DSL.new(self)
        dsl.instance_eval(&block) if block
        dsl.__finalize!
        self
      end

      def async(job_options: ::Kind::Empty::HASH, raise_on_failure: false)
        ::Micro::Case.check.active_job_job_options!(job_options)
        ::Micro::Case::ActiveJob::Caller.new(
          self,
          job_options: job_options,
          raise_on_failure: raise_on_failure
        )
      end

      alias_method :later, :async

      def __active_job_job_class
        return @__active_job_job_class if defined?(@__active_job_job_class)
        nil
      end

      def __active_job_key
        return @__active_job_key if defined?(@__active_job_key)
        nil
      end

      def __active_job_default_options
        return @__active_job_default_options if defined?(@__active_job_default_options)
        {}
      end
    end

    # Propagate active_job state to subclasses (issue: inheritance copies
    # job subclass reference, default_options, and registered key — but a
    # subclass that redeclares `active_job do ... end` must use a fresh key,
    # enforced by the Registry's duplicate-key check).
    module ActiveJobInherited
      def inherited(subclass)
        super

        return unless instance_variable_defined?(:@__active_job_job_class)
        return unless (job_class = instance_variable_get(:@__active_job_job_class))

        subclass.instance_variable_set(:@__active_job_job_class, job_class)
        subclass.instance_variable_set(
          :@__active_job_key, instance_variable_get(:@__active_job_key)
        )
        subclass.instance_variable_set(
          :@__active_job_default_options,
          (instance_variable_get(:@__active_job_default_options) || {}).dup
        )
      end
    end

    singleton_class.prepend(ActiveJobInherited)
  end
end
