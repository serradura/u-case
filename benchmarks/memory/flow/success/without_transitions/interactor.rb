require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  ruby '>= 2.4.0'

  gem 'memory_profiler'

  gem 'interactor', '~> 3.1'
end

class ConvertTextToNumber
  include ::Interactor

  def call
    text = context.text

    if text =~ /\d+/
      context.number = text.to_i
    else
      context.fail! text: 'must be an integer value'
    end
  end
end

class Add1
  include ::Interactor

  def call
    context.number = context.number + 1
  end
end

class Add5
  include ::Interactor::Organizer

  organize(
    ConvertTextToNumber,
    Add1,
    Add1,
    Add1,
    Add1,
    Add1
  )
end

Add5.call(text: '0')

report = MemoryProfiler.report { Add5.call(text: '0') }
report.pretty_print
