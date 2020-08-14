require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'

  gem 'interactor', '~> 3.1', '>= 3.1.1'

  gem 'u-case', '~> 3.0.0.rc8'
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

  x.report('Micro::Case flow using private methods through lambdas') do
    Add2ToAllNumbers::WithMicroCase::FlowUsingPrivateMethodsThroughLambdas.call(NUMBERS)
  end

  x.compare!
end

# Warming up --------------------------------------
# Interactor::Organizer
#                          4.837k i/100ms
# Micro::Cases.flow([])
#                          6.755k i/100ms
# Micro::Cases::safe_flow([])
#                          6.809k i/100ms
# Micro::Case flow using `then` method
#                          6.968k i/100ms
# Micro::Case flow using private methods
#                         10.362k i/100ms
# Micro::Case flow using private methods through lambdas
#                         10.258k i/100ms

# Calculating -------------------------------------
# Interactor::Organizer
#                          50.731k (± 1.6%) i/s -    256.361k in   5.054694s
# Micro::Cases.flow([])
#                          67.757k (± 1.6%) i/s -    344.505k in   5.085681s
# Micro::Cases::safe_flow([])
#                          67.613k (± 1.6%) i/s -    340.450k in   5.036562s
# Micro::Case flow using `then` method
#                          69.483k (± 1.5%) i/s -    348.400k in   5.015351s
# Micro::Case flow using private methods
#                         103.788k (± 1.0%) i/s -    528.462k in   5.092240s
# Micro::Case flow using private methods through lambdas
#                         101.081k (± 1.2%) i/s -    512.900k in   5.074904s

# Comparison:
# Micro::Case flow using private methods:                 103787.5 i/s
# Micro::Case flow using private methods through lambdas: 101080.6 i/s - 1.03x  (± 0.00) slower
# Micro::Case flow using `then` method:                    69483.3 i/s - 1.49x  (± 0.00) slower
# Micro::Cases.flow([]):                                   67757.2 i/s - 1.53x  (± 0.00) slower
# Micro::Cases::safe_flow([]):                             67613.3 i/s - 1.54x  (± 0.00) slower
# Interactor::Organizer:                                   50730.8 i/s - 2.05x  (± 0.00) slower
