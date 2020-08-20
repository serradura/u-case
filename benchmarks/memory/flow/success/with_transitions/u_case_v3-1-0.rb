require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  ruby '>= 2.4.0'

  gem 'memory_profiler'

  gem 'u-case', '~> 3.1.0'
end

Micro::Case.config do |config|
  config.enable_transitions = true
end

class ConvertTextToNumber < Micro::Case
  attribute :text

  def call!
    return Success(result: { number: text.to_i }) if text =~ /\d+/

    Failure result: { text: 'must be an integer value' }
  end
end

class Add1 < Micro::Case
  attribute :number

  def call!
    Success result: { number: number + 1 }
  end
end

Add5 = Micro::Cases.flow([
  ConvertTextToNumber,
  Add1,
  Add1,
  Add1,
  Add1,
  Add1
])

Add5.call(text: '0')

report = MemoryProfiler.report { Add5.call(text: '0') }
report.pretty_print
