require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'

  gem 'interactor', '~> 3.1', '>= 3.1.1'

  gem 'u-case', '~> 3.0.0.rc9'
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

  x.report('Micro::Case flow using private methods through lambdas') do
    Add2ToAllNumbers::WithMicroCase::FlowUsingPrivateMethodsThroughLambdas.call(NUMBERS)
  end

  x.compare!
end

# Warming up --------------------------------------
# Interactor::Organizer
#                          2.299k i/100ms
# Micro::Cases.flow([])
#                         14.187k i/100ms
# Micro::Cases::safe_flow([])
#                         13.609k i/100ms
# Micro::Case flow using `then` method
#                         14.578k i/100ms
# Micro::Case flow using private methods
#                         14.101k i/100ms
# Micro::Case flow using private methods through lambdas
#                         13.670k i/100ms
# Calculating -------------------------------------
# Interactor::Organizer
#                          23.306k (± 2.1%) i/s -    117.249k in   5.033171s
# Micro::Cases.flow([])
#                         140.111k (± 1.6%) i/s -    709.350k in   5.064041s
# Micro::Cases::safe_flow([])
#                         139.927k (± 1.7%) i/s -    707.668k in   5.058971s
# Micro::Case flow using `then` method
#                         146.073k (± 2.0%) i/s -    743.478k in   5.091741s
# Micro::Case flow using private methods
#                         142.092k (± 1.5%) i/s -    719.151k in   5.062298s
# Micro::Case flow using private methods through lambdas
#                         140.791k (± 1.2%) i/s -    710.840k in   5.049584s

# Comparison:
# Micro::Case flow using `then` method:                     146073.0 i/s
# Micro::Case flow using private methods:                   142091.7 i/s - same-ish: difference falls within error
# Micro::Case flow using private methods through lambdas:   140791.1 i/s - 1.04x  (± 0.00) slower
# Micro::Cases.flow([]):                                    140110.8 i/s - 1.04x  (± 0.00) slower
# Micro::Cases::safe_flow([]):                              139926.6 i/s - 1.04x  (± 0.00) slower
# Interactor::Organizer:                                     23305.9 i/s - 6.27x  (± 0.00) slower
