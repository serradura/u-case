require 'test_helper'

class Micro::Case::Result::NotificationsTest < Minitest::Test
  i_suck_and_my_tests_are_order_dependent!

  EVENT_NAME = 'transition.micro_case'.freeze

  def setup
    skip 'ActiveSupport::Notifications not loaded in this bundle' unless Micro::Case::Result::Notifications::Available
    skip 'transitions disabled in this bundle'                    unless Micro::Case::Result.transitions_enabled?

    @events = []
    @subscriber = ::ActiveSupport::Notifications.subscribe(EVENT_NAME) do |*args|
      @events << ::ActiveSupport::Notifications::Event.new(*args)
    end
  end

  def teardown
    ::ActiveSupport::Notifications.unsubscribe(@subscriber) if @subscriber

    Micro::Case.config do |config|
      config.notifications = false
    end

    Micro::Case::Result::Notifications.event_name = Micro::Case::Result::Notifications::DEFAULT_EVENT_NAME
  end

  class SlugifySuccess < Micro::Case
    attribute :title

    def call!
      Success(:slugified, result: { slug: title.downcase })
    end
  end

  class SlugifyFailure < Micro::Case
    attribute :title

    def call!
      Failure(:bad_title, result: { reason: 'blank' })
    end
  end

  class Upcase < Micro::Case
    attribute :slug

    def call!
      Success result: { slug: slug.upcase }
    end
  end

  def test_the_default_value_is_false
    assert_equal(false, Micro::Case::Config.instance.notifications)
  end

  def test_no_events_fire_by_default
    SlugifySuccess.call(title: 'Hello')

    assert_empty(@events)
  end

  def test_setting_to_a_non_boolean_raises
    assert_raises_with_message(
      Kind::Error,
      '"yes" expected to be a kind of Boolean'
    ) do
      Micro::Case.config { |c| c.notifications = 'yes' }
    end
  end

  def test_events_fire_when_enabled
    Micro::Case.config { |c| c.notifications = true }

    SlugifySuccess.call(title: 'Hello')

    assert_equal(1, @events.size)
  end

  def test_payload_schema_keys
    Micro::Case.config { |c| c.notifications = true }

    SlugifySuccess.call(title: 'Hello')

    expected_keys = [:use_case_class, :attributes, :result_type, :result_kind, :result_data, :accessible_attributes].sort

    assert_equal(expected_keys, @events.first.payload.keys.sort)
  end

  def test_payload_values_for_success
    Micro::Case.config { |c| c.notifications = true }

    SlugifySuccess.call(title: 'Hello')

    payload = @events.first.payload

    assert_equal(SlugifySuccess,        payload[:use_case_class])
    assert_equal({ title: 'Hello' },    payload[:attributes])
    assert_equal(:slugified,            payload[:result_type])
    assert_equal(:success,              payload[:result_kind])
    assert_equal({ slug: 'hello' },     payload[:result_data])
    assert_equal([:title],              payload[:accessible_attributes])
  end

  def test_payload_values_for_failure
    Micro::Case.config { |c| c.notifications = true }

    SlugifyFailure.call(title: 'Hello')

    payload = @events.first.payload

    assert_equal(SlugifyFailure,         payload[:use_case_class])
    assert_equal(:bad_title,             payload[:result_type])
    assert_equal(:failure,               payload[:result_kind])
    assert_equal({ reason: 'blank' },    payload[:result_data])
  end

  def test_one_event_per_transition_in_a_flow
    Micro::Case.config { |c| c.notifications = true }

    Micro::Cases.flow([SlugifySuccess, Upcase]).call(title: 'Hello')

    assert_equal(2, @events.size)

    assert_equal(SlugifySuccess, @events[0].payload[:use_case_class])
    assert_equal(Upcase,         @events[1].payload[:use_case_class])
  end

  def test_disabling_after_enabling_silences_events
    Micro::Case.config { |c| c.notifications = true }
    Micro::Case.config { |c| c.notifications = false }

    SlugifySuccess.call(title: 'Hello')

    assert_empty(@events)
  end

  def test_custom_event_name_is_respected
    Micro::Case.config { |c| c.notifications = true }
    Micro::Case.config { |c| c.notifications_event_name = 'use_case.custom' }

    custom_events = []
    subscriber = ::ActiveSupport::Notifications.subscribe('use_case.custom') do |*args|
      custom_events << ::ActiveSupport::Notifications::Event.new(*args)
    end

    begin
      SlugifySuccess.call(title: 'Hello')

      assert_equal(1, custom_events.size)
      assert_empty(@events)
    ensure
      ::ActiveSupport::Notifications.unsubscribe(subscriber)
    end
  end

  def test_custom_mapper_still_wins_for_transitions_and_event_still_fires
    Micro::Case.config { |c| c.notifications = true }

    custom_mapper = ->(result, attrs) { { custom: true, type: result.type } }

    result = Micro::Case::Result.new(custom_mapper)
    use_case = SlugifySuccess.__new__(result, { title: 'Hello' })
    use_case.__call__

    assert_equal([{ custom: true, type: :slugified }], result.transitions)

    assert_equal(1, @events.size)
    assert_equal(SlugifySuccess, @events.first.payload[:use_case_class])
  end

  def test_publish_is_a_noop_when_disabled_even_with_subscriber
    assert_equal(false, Micro::Case::Result::Notifications.enabled)

    Micro::Case::Result::Notifications.publish(Object.new, { irrelevant: true })

    assert_empty(@events)
  end
end

class Micro::Case::Result::NotificationsTransitionsDisabledTest < Minitest::Test
  i_suck_and_my_tests_are_order_dependent!

  EVENT_NAME = 'transition.micro_case'.freeze

  def setup
    skip 'ActiveSupport::Notifications not loaded in this bundle' unless Micro::Case::Result::Notifications::Available
    skip 'transitions enabled in this bundle'                     if Micro::Case::Result.transitions_enabled?

    @events = []
    @subscriber = ::ActiveSupport::Notifications.subscribe(EVENT_NAME) do |*args|
      @events << ::ActiveSupport::Notifications::Event.new(*args)
    end
  end

  def teardown
    ::ActiveSupport::Notifications.unsubscribe(@subscriber) if @subscriber

    Micro::Case.config do |config|
      config.notifications = false
    end
  end

  class Noop < Micro::Case
    def call!; Success(); end
  end

  def test_no_event_when_transitions_are_disabled
    Micro::Case.config { |c| c.notifications = true }

    Noop.call

    assert_empty(@events)
  end
end

class Micro::Case::Result::NotificationsAvailabilityTest < Minitest::Test
  def test_setting_to_true_raises_when_active_support_notifications_is_unavailable
    skip 'ActiveSupport::Notifications is loaded in this bundle' if Micro::Case::Result::Notifications::Available

    assert_raises(Micro::Case::Error::NotificationsUnavailable) do
      Micro::Case.config { |c| c.notifications = true }
    end
  end

  def test_setting_to_false_does_not_raise_when_active_support_notifications_is_unavailable
    skip 'ActiveSupport::Notifications is loaded in this bundle' if Micro::Case::Result::Notifications::Available

    Micro::Case.config { |c| c.notifications = false }

    assert_equal(false, Micro::Case::Config.instance.notifications)
  end

  def test_publish_is_safe_when_unavailable
    skip 'ActiveSupport::Notifications is loaded in this bundle' if Micro::Case::Result::Notifications::Available

    assert_nil(Micro::Case::Result::Notifications.publish(Object.new, {}))
  end
end
