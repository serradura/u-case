# frozen_string_literal: true
#
# Shared runner used by checks_enabled.rb and checks_disabled.rb.
#
# Each caller booted in a fresh Ruby process, sets the MODE constant
# (:enabled or :disabled), then requires this file. We then configure the
# gem once, run all scenarios, and write the benchmark-ips JSON to disk.
#
# The point of the per-mode subprocess split is methodological: toggling
# `Micro::Case.check` inside a single process invalidates Ruby's method
# inline caches and leaves the second mode running on a polluted JIT/GC
# state. Two processes means each mode is measured cold-from-boot with
# its own caches warming for its own dispatch shape.

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  ruby '>= 2.7.0'

  gem 'benchmark-ips', '~> 2.15', '>= 2.15.1'

  gem 'kind', '>= 5.6', '< 7.0'
  gem 'u-attributes', '>= 2.8', '< 4.0'

  gem 'ostruct', '~> 0.6' if RUBY_VERSION >= '3.5'
end

$LOAD_PATH.unshift File.expand_path('../../../../lib', __FILE__)

require 'u-case'
require 'benchmark/ips'

raise 'MODE must be :enabled or :disabled' unless [:enabled, :disabled].include?(MODE)

Micro::Case.config do |config|
  config.enable_transitions     = false
  config.disable_runtime_checks = (MODE == :disabled)
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

# GC between reports so allocation pressure from one scenario does not
# bleed into the next one's window.
class GcIsolatedSuite
  def warming(*);   GC.start; end
  def warmup_stats(*); end
  def running(*);   GC.start; end
  def add_report(*); end
end

json_path = ARGV[0] or raise 'usage: ruby checks_<mode>.rb <output.json>'

puts "Mode: #{MODE}   Ruby: #{RUBY_DESCRIPTION}   Writing → #{json_path}"

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2, iterations: 3, suite: GcIsolatedSuite.new)

  x.report('single_use_case')          { |times| times.times { MultiplyUseCase.call(PARAMS) } }
  x.report('use_case_calling_another') { |times| times.times { CallAnotherUseCase.call(PARAMS) } }
  x.report('flow_3_steps')             { |times| times.times { MULTIPLY_FLOW.call(PARAMS) } }

  x.json! json_path
end
