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

# ++++++++++++++++++++++++++++++++++++++++++++++++++++
# With Micro::Case::Result.disable_transition_tracking
# ++++++++++++++++++++++++++++++++++++++++++++++++++++

# Warming up --------------------------------------
# Interactor::Organizer   2.209k i/100ms
#     Micro::Case::Flow   11.508k i/100ms
# Micro::Case::Safe::Flow 11.605k i/100ms

# Calculating -------------------------------------
# Interactor::Organizer   22.592k (± 2.8%) i/s -    114.868k in   5.088685s
#     Micro::Case::Flow   123.629k (± 2.9%) i/s -    621.432k in   5.030844s
# Micro::Case::Safe::Flow 123.862k (± 3.0%) i/s -    626.670k in   5.064097s

# Comparison:
# Micro::Case::Safe::Flow: 123862.4 i/s
#     Micro::Case::Flow:   123629.3 i/s - same-ish: difference falls within error
# Interactor::Organizer:   22592.2 i/s - 5.48x  slower


# +++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Without Micro::Case::Result.disable_transition_tracking
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Warming up --------------------------------------
# Interactor::Organizer    2.181k i/100ms
#     Micro::Case::Flow    8.915k i/100ms
# Micro::Case::Safe::Flow  8.869k i/100ms
#
# Calculating -------------------------------------
# Interactor::Organizer    23.221k (± 2.9%) i/s -    117.774k in   5.076257s
#     Micro::Case::Flow    93.508k (± 2.9%) i/s -    472.495k in   5.057363s
# Micro::Case::Safe::Flow  93.802k (± 2.3%) i/s -    470.057k in   5.014068s

# Comparison:
# Micro::Case::Safe::Flow:  93801.8 i/s
#     Micro::Case::Flow:    93507.7 i/s - same-ish: difference falls within error
# Interactor::Organizer:    23220.9 i/s - 4.04x  slower
