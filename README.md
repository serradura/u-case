[![Gem](https://img.shields.io/gem/v/u-service.svg?style=flat-square)](https://rubygems.org/gems/u-service)
[![Build Status](https://travis-ci.com/serradura/u-service.svg?branch=master)](https://travis-ci.com/serradura/u-service)
[![Maintainability](https://api.codeclimate.com/v1/badges/a30b18528a317435c2ee/maintainability)](https://codeclimate.com/github/serradura/u-service/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/a30b18528a317435c2ee/test_coverage)](https://codeclimate.com/github/serradura/u-service/test_coverage)

μ-service (Micro::Service)
==========================

Create simple and powerful service objects.

- [μ-service (Micro::Service)](#%ce%bc-service-microservice)
  - [Required Ruby version](#required-ruby-version)
  - [Installation](#installation)
  - [Usage](#usage)
    - [How to create a basic Service Object?](#how-to-create-a-basic-service-object)
    - [How to use the Service Object result hooks?](#how-to-use-the-service-object-result-hooks)
    - [How to create a pipeline of Service Objects?](#how-to-create-a-pipeline-of-service-objects)
    - [What is a strict Service Object?](#what-is-a-strict-service-object)
    - [How to validate Service Object attributes?](#how-to-validate-service-object-attributes)
  - [Development](#development)
  - [Contributing](#contributing)
  - [License](#license)
  - [Code of Conduct](#code-of-conduct)

## Required Ruby version

> \>= 2.2.0

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'u-service'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install u-service

## Usage

### How to create a basic Service Object?

```ruby
class Multiply < Micro::Service::Base
  attributes :a, :b

  def call!
    if a.is_a?(Numeric) && b.is_a?(Numeric)
      Success(a * b)
    else
      Failure(:invalid_data)
    end
  end
end

#====================#
# Calling a service  #
#====================#

result = Multiply.call(a: 2, b: 2)
p result.success? # true
p result.value    # 4

#----------------------------#
# Calling a service instance #
#----------------------------#

result = Multiply.new(a: 2, b: 3).call
p result.success? # true
p result.value    # 6

#===========================#
# Verify the result failure #
#===========================#

result = Multiply.call(a: '2', b: 2)
p result.success? # false
p result.failure? # true
p result.value    # :invalid_data
```

### How to use the Service Object result hooks?

```ruby
class Double < Micro::Service::Base
  attributes :number

  def call!
    return Failure(:invalid) { 'the number must be a numeric value' } unless number.is_a?(Numeric)
    return Failure(:lte_zero) { 'the number must be greater than 0' } if number <= 0

    Success(number * number)
  end
end

#================================#
# Printing the output if success #
#================================#

Double
  .call(number: 3)
  .on_success { |number| p number }
  .on_failure(:invalid) { |msg| raise TypeError, msg }
  .on_failure(:lte_zero) { |msg| raise ArgumentError, msg }

# The output when is a success:
# 9

#=============================#
# Raising an error if failure #
#=============================#

Double
  .call(number: -1)
  .on_success { |number| p number }
  .on_failure(:invalid) { |msg| raise TypeError, msg }
  .on_failure(:lte_zero) { |msg| raise ArgumentError, msg }

# The output (raised an error) when is a failure:
# ArgumentError (the number must be greater than 0)
```

### How to create a pipeline of Service Objects?

```ruby
module Steps
  class ConvertToNumbers < Micro::Service::Base
    attribute :relation

    def call!
      if relation.all? { |value| String(value) =~ /\d+/ }
        Success(numbers: relation.map(&:to_i))
      else
        Failure('relation must contain only numbers')
      end
    end
  end

  class Add2 < Micro::Service::Strict
    attribute :numbers

    def call!
      Success(numbers.map { |number| number + 2 })
    end
  end

  class Double < Micro::Service::Strict
    attribute :numbers

    def call!
      Success(numbers.map { |number| number * number })
    end
  end
end

Add2ToAllNumbers = Micro::Service::Pipeline[
  Steps::ConvertToNumbers,
  Steps::Add2
]

DoubleAllNumbers = Micro::Service::Pipeline[
  Steps::ConvertToNumbers,
  Steps::Double
]

result = Add2ToAllNumbers.call(relation: %w[1 1 2 2 3 4])

p result.success? # true
p result.value    # [3, 3, 4, 4, 5, 6]

DoubleAllNumbers
  .call(relation: %w[1 1 b 2 3 4])
  .on_failure { |message| p message } # "relation must contain only numbers"
```

### What is a strict Service Object?

A: Is a service object which will require all keywords (attributes) on its initialization.

```ruby
class Double < Micro::Service::Strict
  attribute :numbers

  def call!
    Success(numbers.map { |number| number * number })
  end
end

Double.call({})

# The output (raised an error):
# ArgumentError (missing keyword: :numbers)
```

### How to validate Service Object attributes?

Note: To do this your application must have the (activemodel >= 3.2)(https://rubygems.org/gems/activemodel) as a dependency.

```ruby
#
# By default, if your project has the activemodel
# any kind of service attribute can be validated.
#
class Multiply < Micro::Service::Base
  attribute :a
  attribute :b
  validates :a, :b, presence: true, numericality: true

  def call!
    return Success(number: a * b) if valid?

    Failure(errors: self.errors)
  end
end

#
# But if do you want an automatic way to fail
# your services if there is some invalid data.
# You can use:
require 'micro/service/with_validation'

# Using this approach, you can rewrite the previous sample with fewer lines of code.

class Multiply < Micro::Service::WithValidation
  attribute :a
  attribute :b
  validates :a, :b, presence: true, numericality: true

  def call!
    Success(number: a * b)
  end
end

# Note:
# There is a strict variation for Micro::Service::WithValidation
# Use Micro::Service::Strict::Validation if do you want this behavior.
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/serradura/u-service. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Micro::Service project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/serradura/u-service/blob/master/CODE_OF_CONDUCT.md).
