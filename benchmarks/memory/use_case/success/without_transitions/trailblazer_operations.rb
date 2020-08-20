require 'forwardable'

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  ruby '>= 2.4.0'

  gem 'memory_profiler'

  gem 'trailblazer-activity', '~> 0.10.1'
  gem 'trailblazer-operation', '~> 0.6.2', require: 'trailblazer/operation'
end

class Multiply < Trailblazer::Operation
  step :calculate

  private

    def calculate(options, a:, b:)
      if a.is_a?(Numeric) && b.is_a?(Numeric)
        options[:number] = a * b
      end
    end
end

Multiply.call(a: 2, 'b' => 2)

report = MemoryProfiler.report do
  Multiply.call(a: 2, 'b' => 2)
end

report.pretty_print
