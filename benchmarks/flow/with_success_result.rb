require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'

  gem 'interactor', '~> 3.1', '>= 3.1.1'

  gem 'u-case', '~> 2.6.0'
end

require 'benchmark/ips'

require_relative 'add2_to_all_numbers'

Micro::Case::Result.disable_transition_tracking

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

# ++++++++++++++++++++++++++++++++++++++++++++++++++++
# With Micro::Case::Result.disable_transition_tracking
# ++++++++++++++++++++++++++++++++++++++++++++++++++++

# Warming up --------------------------------------
# Interactor::Organizer    4.765k i/100ms
#     Micro::Case::Flow    5.372k i/100ms
# Micro::Case::Safe::Flow  5.855k i/100ms
# Calculating -------------------------------------
# Interactor::Organizer    48.598k (± 5.2%) i/s -    243.015k in   5.014307s
#     Micro::Case::Flow    61.606k (± 4.4%) i/s -    311.576k in   5.068602s
# Micro::Case::Safe::Flow  60.688k (± 4.8%) i/s -    304.460k in   5.028877s

# Comparison:
#     Micro::Case::Flow:    61606.3 i/s
# Micro::Case::Safe::Flow:  60688.3 i/s - same-ish: difference falls within error
# Interactor::Organizer:    48598.2 i/s - 1.27x  slower


# +++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Without Micro::Case::Result.disable_transition_tracking
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Warming up --------------------------------------
# Interactor::Organizer    4.889k i/100ms
#     Micro::Case::Flow    4.472k i/100ms
# Micro::Case::Safe::Flow  4.488k i/100ms
# Calculating -------------------------------------
# Interactor::Organizer    50.705k (± 3.8%) i/s -    254.228k in   5.021142s
#     Micro::Case::Flow    45.938k (± 5.2%) i/s -    232.544k in   5.077276s
# Micro::Case::Safe::Flow  46.412k (± 3.5%) i/s -    233.376k in   5.035084s

# Comparison:
# Interactor::Organizer:    50705.4 i/s
# Micro::Case::Safe::Flow:  46411.7 i/s - 1.09x  slower
#     Micro::Case::Flow:    45938.4 i/s - 1.10x  slower
