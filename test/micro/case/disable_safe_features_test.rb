require 'test_helper'

class Micro::Case::DisableSafeFeaturesTest < Minitest::Test
  i_suck_and_my_tests_are_order_dependent!

  def teardown
    Micro::Case.config do |config|
      config.disable_safe_features = false
    end
  end

  def test_the_default_value_is_false
    assert_equal(false, Micro::Case::Config.instance.disable_safe_features)
  end

  def test_it_only_accepts_a_boolean_value
    assert_raises_with_message(
      Kind::Error,
      '"yes" expected to be a kind of Boolean'
    ) do
      Micro::Case.config do |config|
        config.disable_safe_features = 'yes'
      end
    end
  end

  def test_subclassing_safe_raises_when_disabled
    Micro::Case.config do |config|
      config.disable_safe_features = true
    end

    err = assert_raises(Micro::Case::Error::SafeFeaturesDisabled) do
      Class.new(Micro::Case::Safe) { def call!; Success(); end }
    end

    assert_match(/Micro::Case::Safe/, err.message)
  end

  def test_calling_safe_flow_raises_when_disabled
    Micro::Case.config do |config|
      config.disable_safe_features = true
    end

    use_case = Class.new(Micro::Case) { def call!; Success(); end }

    err = assert_raises(Micro::Case::Error::SafeFeaturesDisabled) do
      Micro::Cases.safe_flow([use_case])
    end

    assert_match(/Micro::Cases\.safe_flow/, err.message)
  end

  def test_calling_on_exception_raises_when_disabled
    Micro::Case.config do |config|
      config.disable_safe_features = true
    end

    use_case = Class.new(Micro::Case) do
      def call!; Success(result: { number: 1 }); end
    end

    err = assert_raises(Micro::Case::Error::SafeFeaturesDisabled) do
      use_case.call.on_exception { }
    end

    assert_match(/Micro::Case::Result#on_exception/, err.message)
  end

  def test_safe_features_work_when_toggled_back_off
    Micro::Case.config do |config|
      config.disable_safe_features = true
    end

    Micro::Case.config do |config|
      config.disable_safe_features = false
    end

    klass = Class.new(Micro::Case::Safe) do
      attribute :n
      def call!; Success(result: { v: n }); end
    end

    assert_equal(false, Micro::Case::Config.instance.disable_safe_features)
    assert_kind_of(Micro::Case::Result, klass.call(n: 1))

    use_case = Class.new(Micro::Case) { def call!; Success(); end }
    assert_kind_of(Micro::Cases::Flow, Micro::Cases.safe_flow([use_case]))

    called = false
    use_case.call.on_exception { called = true }
    assert_equal(false, called)
  end
end
