require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'

  gem 'interactor', '~> 3.1', '>= 3.1.1'

  gem 'u-case', '~> 2.0.0'
end

require 'benchmark/ips'

require_relative 'add2_to_all_numbers'

NUMBERS = {numbers: %w[1 1 2 2 3 4]}

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
#   Interactor::Organizer  4.880k i/100ms
#       Micro::Case::Flow  7.035k i/100ms
# Micro::Case::Safe::Flow  7.059k i/100ms

# Calculating -------------------------------------
#   Interactor::Organizer  50.208k (± 1.3%) i/s -    253.760k in   5.055099s
#       Micro::Case::Flow  73.791k (± 0.9%) i/s -    372.855k in   5.053311s
# Micro::Case::Safe::Flow  73.314k (± 1.1%) i/s -    367.068k in   5.007473s

# Comparison:
#       Micro::Case::Flow: 73790.7 i/s
# Micro::Case::Safe::Flow: 73313.7 i/s - same-ish: difference falls within error
#   Interactor::Organizer: 50207.7 i/s - 1.47x  slower
