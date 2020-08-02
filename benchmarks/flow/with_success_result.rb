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

NUMBERS = {numbers: %w[1 1 2 2 3 4]}

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
# Interactor::Organizer                   5.219k i/100ms
# Micro::Cases.flow([])                   6.451k i/100ms
# Micro::Cases::safe_flow([])             6.421k i/100ms
# Micro::Case flow using `then` method    7.139k i/100ms
# Micro::Case flow using private methods 10.355k i/100ms

# Calculating -------------------------------------
# Interactor::Organizer                    52.959k (± 1.7%) i/s -    266.169k in   5.027332s
# Micro::Cases.flow([])                    63.947k (± 1.7%) i/s -    322.550k in   5.045597s
# Micro::Cases::safe_flow([])              63.047k (± 3.1%) i/s -    321.050k in   5.097228s
# Micro::Case flow using `then` method     69.644k (± 4.0%) i/s -    349.811k in   5.031120s
# Micro::Case flow using private methods  103.297k (± 1.4%) i/s -    517.750k in   5.013254s

# Comparison:
# Micro::Case flow using private methods: 103297.4 i/s
# Micro::Case flow using `then` method:    69644.0 i/s - 1.48x  (± 0.00) slower
# Micro::Cases.flow([]):                   63946.7 i/s - 1.62x  (± 0.00) slower
# Micro::Cases::safe_flow([]):             63047.2 i/s - 1.64x  (± 0.00) slower
# Interactor::Organizer:                   52958.9 i/s - 1.95x  (± 0.00) slower
