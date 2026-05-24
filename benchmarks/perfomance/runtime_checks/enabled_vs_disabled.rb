require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  ruby '>= 2.7.0'

  gem 'benchmark-ips', '~> 2.15', '>= 2.15.1'

  # Runtime deps of the local u-case checkout (the gemspec ranges):
  gem 'kind', '>= 5.6', '< 7.0'
  gem 'u-attributes', '>= 2.8', '< 4.0'

  # Required by `kind` on Ruby 3.5+ (ostruct stopped being a default gem).
  gem 'ostruct', '~> 0.6' if RUBY_VERSION >= '3.5'
end

$LOAD_PATH.unshift File.expand_path('../../../../lib', __FILE__)

require 'u-case'

Micro::Case.config do |config|
  config.enable_transitions = false
end

class MultiplyUseCase < Micro::Case
  attributes :a, :b

  def call!
    if a.is_a?(Numeric) && b.is_a?(Numeric)
      Success result: { number: a * b }
    else
      Failure(:invalid_data)
    end
  end
end

class AddOneUseCase < Micro::Case
  attribute :number

  def call!
    Success result: { number: number + 1 }
  end
end

class CallAnotherUseCase < Micro::Case
  attributes :a, :b

  def call!
    call(MultiplyUseCase)
  end
end

MULTIPLY_FLOW = Micro::Cases.flow([MultiplyUseCase, AddOneUseCase, AddOneUseCase])

PARAMS = { a: 2, b: 3 }.freeze

require 'benchmark/ips'

# Custom Suite that triggers a major GC between reports so that one report's
# allocation pressure does not bleed into the next one's measurement window.
# benchmark-ips fires :warming/:warmup_stats/:running/:add_report around each
# report; we hook the boundaries.
class GcIsolatedSuite
  def warming(*);   GC.start; end
  def warmup_stats(*); end
  def running(*);   GC.start; end
  def add_report(*); end
end

def benchmark(label)
  puts "\n#{'=' * 70}"
  puts label
  puts '=' * 70

  Benchmark.ips do |x|
    x.config(time: 5, warmup: 2, iterations: 3, suite: GcIsolatedSuite.new)

    Micro::Case.config { |c| c.disable_runtime_checks = false }
    x.report('checks enabled  (default)') { |times| times.times { yield } }

    Micro::Case.config { |c| c.disable_runtime_checks = true }
    x.report('checks disabled         ') { |times| times.times { yield } }

    x.compare!
  end
ensure
  Micro::Case.config { |c| c.disable_runtime_checks = false }
end

benchmark('Single use case (Micro::Case)') do
  MultiplyUseCase.call(PARAMS)
end

benchmark('Use case calling another use case') do
  CallAnotherUseCase.call(PARAMS)
end

benchmark('Flow with 3 steps (Micro::Cases.flow)') do
  MULTIPLY_FLOW.call(PARAMS)
end

# How to run:
#   unset BUNDLE_GEMFILE && ruby benchmarks/perfomance/runtime_checks/enabled_vs_disabled.rb
#
# Sample runs on Apple Silicon, 3 iterations of 2s warmup + 5s measurement
# per report:
#
#                                         enabled (default)     disabled
#   Ruby 4.0.1 +PRISM
#     Single use case                  :  195.2k (±3.1%)        194.0k (±2.6%)  → "same-ish"
#     Use case calling another use case:   95.0k (±4.1%)         95.5k (±2.9%)  → "same-ish"
#     Flow with 3 steps                :   59.8k (±3.9%)         60.7k (±3.4%)  → "same-ish"
#
#   Ruby 2.7.8 (no JIT)
#     Single use case                  :  189.4k (±2.6%)        190.0k (±2.6%)  → "same-ish"
#     Use case calling another use case:  101.9k (±1.3%)        101.6k (±3.5%)  → "same-ish"
#     Flow with 3 steps                :   64.9k (±2.9%)         64.3k (±1.1%)  → "same-ish"
#
# Finding: the two modes are statistically indistinguishable on both modern
# (Ruby 4.x +PRISM) and older (Ruby 2.7) interpreters. The checks themselves
# are cheap `is_a?` / `Micro.case_or_flow?` calls, and the extra method
# dispatch through `Micro::Case.check` (one method send per call site) eats
# most of what's saved on the disabled side.
#
# Where the toggle may still matter:
#   - Very hot failure paths that would otherwise allocate exception objects
#     (the curated `Micro::Case::Error::*` constructors are skipped when
#     disabled)
#   - Custom check methods you add to `Check::Enabled` that are heavier than
#     the defaults
#   - Workloads with many more use case invocations per request than this
#     benchmark exercises
#
# Re-run on your target Ruby + workload before deciding. The toggle exists;
# on the default checks measured here, the win is below the noise floor.
