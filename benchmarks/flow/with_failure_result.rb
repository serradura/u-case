require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'

  gem 'interactor', '~> 3.1', '>= 3.1.1'

  gem 'u-case', '~> 2.0.0'
end

require 'benchmark/ips'

require_relative 'add2_to_all_numbers'

NUMBERS = {numbers: %w[1 1 2 2 c 4]}

Benchmark.ips do |x|
  x.config(:time => 5, :warmup => 2)

  x.time = 5
  x.warmup = 2

  x.report('Interactor::Organizer') do
    Add2ToAllNumbers::WithInteractor::Organizer.call(NUMBERS)
  end

  x.report('Micro::Case::Flow') do
    Add2ToAllNumbers::WithMicroCase::Flow.call(NUMBERS)
  end

  x.report('Micro::Case::Safe::Flow') do
    Add2ToAllNumbers::WithMicroCase::SafeFlow.call(NUMBERS)
  end

  x.compare!
end

# Warming up --------------------------------------
#   Interactor::Organizer   2.372k i/100ms
#       Micro::Case::Flow   12.802k i/100ms
# Micro::Case::Safe::Flow   12.673k i/100ms

# Calculating -------------------------------------
#   Interactor::Organizer   24.522k (± 2.0%) i/s -    123.344k in   5.032159s
#       Micro::Case::Flow   135.122k (± 1.7%) i/s -    678.506k in   5.022903s
# Micro::Case::Safe::Flow   133.980k (± 1.4%) i/s -    671.669k in   5.014181s

# Comparison:
#       Micro::Case::Flow:   135122.0 i/s
# Micro::Case::Safe::Flow:   133979.8 i/s - same-ish: difference falls within error
#   Interactor::Organizer:   24521.8 i/s - 5.51x  slower
