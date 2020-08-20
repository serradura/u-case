require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  ruby '>= 2.4.0'

  gem 'memory_profiler'

  gem 'u-case', '~> 2.0.0'
end

class ConvertTextToNumber < Micro::Case
  attribute :text

  def call!
    return Success(number: text.to_i) if text =~ /\d+/

    Failure { { text: 'must be an integer value' } }
  end
end

class Add1 < Micro::Case
  attribute :number

  def call!
    Success(number: number + 1)
  end
end

Add5 = Micro::Case::Flow([
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
