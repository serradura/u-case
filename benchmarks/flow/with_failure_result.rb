require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'

  gem 'interactor', '~> 3.1', '>= 3.1.1'

  gem 'u-case', '~> 3.0.0.rc4'
end

require 'benchmark/ips'

require_relative 'add2_to_all_numbers'

Micro::Case.config do |config|
  # Use to enable/disable the `Micro::Case::Results#transitions` tracking.
  config.enable_transitions = false
end

NUMBERS = {numbers: %w[1 1 2 2 c 4]}

Benchmark.ips do |x|
  x.config(:time => 5, :warmup => 2)

  x.time = 5
  x.warmup = 2

  x.report('Interactor::Organizer') do
    Add2ToAllNumbers::WithInteractor::Organizer.call(NUMBERS)
  end

  x.report('Micro::Cases.flow([])') do
    Add2ToAllNumbers::WithMicroCase::Flow.call(NUMBERS)
  end

  x.report('Micro::Cases::safe_flow([])') do
    Add2ToAllNumbers::WithMicroCase::SafeFlow.call(NUMBERS)
  end

  x.report('Micro::Case flow using `then` method') do
    Add2ToAllNumbers::WithMicroCase::FlowUsingThen.call(NUMBERS)
  end

  x.report('Micro::Case flow using private methods') do
    Add2ToAllNumbers::WithMicroCase::FlowUsingPrivateMethods.call(NUMBERS)
  end

  x.compare!
end

# Warming up --------------------------------------
# Interactor::Organizer                  2.381k i/100ms
# Micro::Cases.flow([])                  12.003k i/100ms
# Micro::Cases::safe_flow([])            12.771k i/100ms
# Micro::Case flow using `then` method   15.085k i/100ms
# Micro::Case flow using private methods 14.254k i/100ms

# Calculating -------------------------------------
# Interactor::Organizer                  23.579k (± 3.2%) i/s -    119.050k in   5.054410s
# Micro::Cases.flow([])                  124.072k (± 3.4%) i/s -    624.156k in   5.036618s
# Micro::Cases::safe_flow([])            124.894k (± 3.6%) i/s -    625.779k in   5.017494s
# Micro::Case flow using `then` method   145.370k (± 4.8%) i/s -    739.165k in   5.096972s
# Micro::Case flow using private methods 139.753k (± 5.6%) i/s -    698.446k in   5.015207s

# Comparison:
# Micro::Case flow using `then` method:   145369.7 i/s
# Micro::Case flow using private methods: 139753.4 i/s - same-ish: difference falls within error
# Micro::Cases::safe_flow([]):            124893.7 i/s - 1.16x  (± 0.00) slower
# Micro::Cases.flow([]):                  124071.8 i/s - 1.17x  (± 0.00) slower
# Interactor::Organizer:                  23578.7 i/s - 6.17x  (± 0.00) slower
