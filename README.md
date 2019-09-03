[![Gem](https://img.shields.io/gem/v/u-case.svg?style=flat-square)](https://rubygems.org/gems/u-case)
[![Build Status](https://travis-ci.com/serradura/u-service.svg?branch=master)](https://travis-ci.com/serradura/u-service)
[![Maintainability](https://api.codeclimate.com/v1/badges/a30b18528a317435c2ee/maintainability)](https://codeclimate.com/github/serradura/u-service/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/a30b18528a317435c2ee/test_coverage)](https://codeclimate.com/github/serradura/u-service/test_coverage)

μ-case (Micro::Case)
==========================

Create simple and powerful service objects.

The main goals of this project are:
1. Be simple to use and easy to learn (input **>>** process/transform **>>** output).
2. Referential transparency and data integrity.
3. No callbacks (before, after, around...).
4. Compose a pipeline of service objects to represents complex business logic.

## Table of Contents <!-- omit in toc -->
- [μ-service (Micro::Case)](#%ce%bc-service-microservice)
  - [Required Ruby version](#required-ruby-version)
  - [Installation](#installation)
  - [Usage](#usage)
    - [How to define a service object?](#how-to-define-a-service-object)
    - [What is a `Micro::Case::Result`?](#what-is-a-microserviceresult)
      - [What are the default types of a `Micro::Case::Result`?](#what-are-the-default-types-of-a-microserviceresult)
      - [How to define custom result types?](#how-to-define-custom-result-types)
      - [Is it possible to define a custom result type without a block?](#is-it-possible-to-define-a-custom-result-type-without-a-block)
      - [How to use the result hooks?](#how-to-use-the-result-hooks)
      - [What happens if a result hook is declared multiple times?](#what-happens-if-a-result-hook-is-declared-multiple-times)
    - [How to create a pipeline of service objects?](#how-to-create-a-pipeline-of-service-objects)
      - [Is it possible to compose pipelines with other pipelines?](#is-it-possible-to-compose-pipelines-with-other-pipelines)
    - [What is a strict service object?](#what-is-a-strict-service-object)
    - [Is there some feature to auto handle exceptions inside of services/pipelines?](#is-there-some-feature-to-auto-handle-exceptions-inside-of-servicespipelines)
    - [How to validate service object attributes?](#how-to-validate-service-object-attributes)
    - [Examples](#examples)
  - [Comparisons](#comparisons)
  - [Benchmarks](#benchmarks)
  - [Development](#development)
  - [Contributing](#contributing)
  - [License](#license)
  - [Code of Conduct](#code-of-conduct)

## Required Ruby version

> \>= 2.2.0

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'u-case'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install u-case

## Usage

### How to define a service object?

```ruby
class Multiply < Micro::Case::Base
  # 1. Define its inputs as attributes
  attributes :a, :b

  # 2. Define the method `call!` with its business logic
  def call!

    # 3. Return the calling result using the `Success()` and `Failure()` methods
    if a.is_a?(Numeric) && b.is_a?(Numeric)
      Success(a * b)
    else
      Failure { '`a` and `b` attributes must be numeric' }
    end
  end
end

#================================#
# Calling a service object class #
#================================#

# Success result

result = Multiply.call(a: 2, b: 2)

result.success? # true
result.value    # 4

# Failure result

bad_result = Multiply.call(a: 2, b: '2')

bad_result.failure? # true
bad_result.value    # "`a` and `b` attributes must be numeric"

#-----------------------------------#
# Calling a service object instance #
#-----------------------------------#

result = Multiply.new(a: 2, b: 3).call

result.value # 6

# Note:
# ----
# The result of a Micro::Case::Base.call
# is an instance of Micro::Case::Result
```

[⬆️ Back to Top](#table-of-contents-)

### What is a `Micro::Case::Result`?

A `Micro::Case::Result` stores the output data of some service object. These are their main methods:
- `#success?` returns true if is a successful result.
- `#failure?` returns true if is an unsuccessful result.
- `#value` the result value itself.
- `#type` a Symbol which gives meaning for the result, this is useful to declare different types of failures or success.
- `#on_success` or `#on_failure` are hook methods which help you define the flow of your application.
- `#service` if the result is a failure the service will be accessible through this method. This feature is handy to handle pipeline failures (this topic will be covered ahead).

[⬆️ Back to Top](#table-of-contents-)

#### What are the default types of a `Micro::Case::Result`?

Every result has a type and these are the default values: :ok when success, and :error/:exception when failures.

```ruby
class Divide < Micro::Case::Base
  attributes :a, :b

  def call!
    invalid_attributes.empty? ? Success(a / b) : Failure(invalid_attributes)
  rescue => e
    Failure(e)
  end

  private def invalid_attributes
    attributes.select { |_key, value| !value.is_a?(Numeric) }
  end
end

# Success result

result = Divide.call(a: 2, b: 2)

result.type     # :ok
result.value    # 1
result.success? # true
result.service  # raises `Micro::Case::Error::InvalidAccessToTheServiceObject: only a failure result can access its service object`

# Failure result - type == :error

bad_result = Divide.call(a: 2, b: '2')

bad_result.type     # :error
bad_result.value    # {"b"=>"2"}
bad_result.failure? # true
bad_result.service  # #<Divide:0x0000 @__attributes={"a"=>2, "b"=>"2"}, @a=2, @b="2", @__result=#<Micro::Case::Result:0x0000 @service=#<Divide:0x0000 ...>, @type=:error, @value={"b"=>"2"}, @success=false>>

# Failure result - type == :exception

err_result = Divide.call(a: 2, b: 0)

err_result.type     # :exception
err_result.value    # <ZeroDivisionError: divided by 0>
err_result.failure? # true
err_result.service  # #<Divide:0x0000 @__attributes={"a"=>2, "b"=>0}, @a=2, @b=0, @__result=#<Micro::Case::Result:0x0000 @service=#<Divide:0x0000 ...>, @type=:exception, @value=#<ZeroDivisionError: divided by 0>, @success=false>>

# Note:
# ----
# Any Exception instance which is wrapped by
# the Failure() method will receive `:exception` instead of the `:error` type.
```

[⬆️ Back to Top](#table-of-contents-)

#### How to define custom result types?

Answer: Use a symbol as the argument of Success() and Failure() methods and declare a block to set their values.

```ruby
class Multiply < Micro::Case::Base
  attributes :a, :b

  def call!
    return Success(a * b) if a.is_a?(Numeric) && b.is_a?(Numeric)

    Failure(:invalid_data) do
      attributes.reject { |_, input| input.is_a?(Numeric) }
    end
  end
end

# Success result

result = Multiply.call(a: 3, b: 2)

result.type     # :ok
result.value    # 6
result.success? # true

# Failure result

bad_result = Multiply.call(a: 3, b: '2')

bad_result.type     # :invalid_data
bad_result.value    # {"b"=>"2"}
bad_result.failure? # true
```

[⬆️ Back to Top](#table-of-contents-)

#### Is it possible to define a custom result type without a block?

Answer: Yes, it is. But only for failure results!

```ruby
class Multiply < Micro::Case::Base
  attributes :a, :b

  def call!
    return Failure(:invalid_data) unless a.is_a?(Numeric) && b.is_a?(Numeric)

    Success(a * b)
  end
end

result = Multiply.call(a: 2, b: '2')

result.failure?           #true
result.value              #:invalid_data
result.type               #:invalid_data
result.service.attributes # {"a"=>2, "b"=>"2"}

# Note:
# ----
# This feature is handy to handle pipeline failures
# (this topic will be covered ahead).
```

[⬆️ Back to Top](#table-of-contents-)

#### How to use the result hooks?

As mentioned earlier, the `Micro::Case::Result` has two methods to improve the flow control. They are: `#on_success`, `on_failure`.

The examples below show how to use them:

```ruby
class Double < Micro::Case::Base
  attributes :number

  def call!
    return Failure(:invalid) { 'the number must be a numeric value' } unless number.is_a?(Numeric)
    return Failure(:lte_zero) { 'the number must be greater than 0' } if number <= 0

    Success(number * 2)
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

# The output because is a success:
#   6

#=============================#
# Raising an error if failure #
#=============================#

Double
  .call(number: -1)
  .on_success { |number| p number }
  .on_failure { |_msg, service| puts "#{service.class.name} was the service responsible for the failure" }
  .on_failure(:invalid) { |msg| raise TypeError, msg }
  .on_failure(:lte_zero) { |msg| raise ArgumentError, msg }

# The outputs because is a failure:
#   Double was the service responsible for the failure
# (throws the error)
#   ArgumentError (the number must be greater than 0)

# Note:
# ----
# The service responsible for the failure will be accessible as the second hook argument
```

[⬆️ Back to Top](#table-of-contents-)

#### What happens if a result hook is declared multiple times?

Answer: The hook will be triggered if it matches the result type.

```ruby
class Double < Micro::Case::Base
  attributes :number

  def call!
    return Failure(:invalid) { 'the number must be a numeric value' } unless number.is_a?(Numeric)

    Success(:computed) { number * 2 }
  end
end

result = Double.call(number: 3)
result.value     # 6
result.value * 4 # 24

accum = 0

result.on_success { |number| accum += number }
      .on_success { |number| accum += number }
      .on_success(:computed) { |number| accum += number }
      .on_success(:computed) { |number| accum += number }

accum # 24

result.value * 4 == accum # true
```

[⬆️ Back to Top](#table-of-contents-)

### How to create a pipeline of service objects?

```ruby
module Steps
  class ConvertToNumbers < Micro::Case::Base
    attribute :numbers

    def call!
      if numbers.all? { |value| String(value) =~ /\d+/ }
        Success(numbers: numbers.map(&:to_i))
      else
        Failure('numbers must contain only numeric types')
      end
    end
  end

  class Add2 < Micro::Case::Strict
    attribute :numbers

    def call!
      Success(numbers: numbers.map { |number| number + 2 })
    end
  end

  class Double < Micro::Case::Strict
    attribute :numbers

    def call!
      Success(numbers: numbers.map { |number| number * 2 })
    end
  end

  class Square < Micro::Case::Strict
    attribute :numbers

    def call!
      Success(numbers: numbers.map { |number| number * number })
    end
  end
end

#-------------------------------------------------#
# Creating a pipeline using the collection syntax #
#-------------------------------------------------#

Add2ToAllNumbers = Micro::Case::Pipeline[
  Steps::ConvertToNumbers,
  Steps::Add2
]

result = Add2ToAllNumbers.call(numbers: %w[1 1 2 2 3 4])

p result.success? # true
p result.value    # {:numbers => [3, 3, 4, 4, 5, 6]}

#-------------------------------------------------------#
# An alternative way to create a pipeline using classes #
#-------------------------------------------------------#

class DoubleAllNumbers
  include Micro::Case::Pipeline

  pipeline Steps::ConvertToNumbers, Steps::Double
end

DoubleAllNumbers
  .call(numbers: %w[1 1 b 2 3 4])
  .on_failure { |message| p message } # "numbers must contain only numeric types"

#-----------------------------------------------------------------#
# Another way to create a pipeline using the composition operator #
#-----------------------------------------------------------------#

SquareAllNumbers =
  Steps::ConvertToNumbers >> Steps::Square

SquareAllNumbers
  .call(numbers: %w[1 1 2 2 3 4])
  .on_success { |value| p value[:numbers] } # [1, 1, 4, 4, 9, 16]

# Note:
# ----
# When happening a failure, the service object responsible for this
# will be accessible in the result

result = SquareAllNumbers.call(numbers: %w[1 1 b 2 3 4])

result.failure?                               # true
result.service.is_a?(Steps::ConvertToNumbers) # true

result.on_failure do |_message, service|
  puts "#{service.class.name} was the service responsible for the failure" } # Steps::ConvertToNumbers was the service responsible for the failure
end
```

[⬆️ Back to Top](#table-of-contents-)

#### Is it possible to compose pipelines with other pipelines?

Answer: Yes, it is.

```ruby
module Steps
  class ConvertToNumbers < Micro::Case::Base
    attribute :numbers

    def call!
      if numbers.all? { |value| String(value) =~ /\d+/ }
        Success(numbers: numbers.map(&:to_i))
      else
        Failure('numbers must contain only numeric types')
      end
    end
  end

  class Add2 < Micro::Case::Strict
    attribute :numbers

    def call!
      Success(numbers: numbers.map { |number| number + 2 })
    end
  end

  class Double < Micro::Case::Strict
    attribute :numbers

    def call!
      Success(numbers: numbers.map { |number| number * 2 })
    end
  end

  class Square < Micro::Case::Strict
    attribute :numbers

    def call!
      Success(numbers: numbers.map { |number| number * number })
    end
  end
end

Add2ToAllNumbers = Steps::ConvertToNumbers >> Steps::Add2
DoubleAllNumbers = Steps::ConvertToNumbers >> Steps::Double
SquareAllNumbers = Steps::ConvertToNumbers >> Steps::Square

DoubleAllNumbersAndAdd2 = DoubleAllNumbers >> Steps::Add2
SquareAllNumbersAndAdd2 = SquareAllNumbers >> Steps::Add2

SquareAllNumbersAndDouble = SquareAllNumbersAndAdd2 >> DoubleAllNumbers
DoubleAllNumbersAndSquareAndAdd2 = DoubleAllNumbers >> SquareAllNumbersAndAdd2

SquareAllNumbersAndDouble
  .call(numbers: %w[1 1 2 2 3 4])
  .on_success { |value| p value[:numbers] } # [6, 6, 12, 12, 22, 36]

DoubleAllNumbersAndSquareAndAdd2
  .call(numbers: %w[1 1 2 2 3 4])
  .on_success { |value| p value[:numbers] } # [6, 6, 18, 18, 38, 66]
```

Note: You can blend any of the [syntaxes/approaches to create the pipelines](#how-to-create-a-pipeline-of-service-objects)) - [examples](https://github.com/serradura/u-service/blob/master/test/micro/case/pipeline/blend_test.rb#L7-L34).

[⬆️ Back to Top](#table-of-contents-)

### What is a strict service object?

Answer: Is a service object which will require all the keywords (attributes) on its initialization.

```ruby
class Double < Micro::Case::Strict
  attribute :numbers

  def call!
    Success(numbers.map { |number| number * 2 })
  end
end

Double.call({})

# The output (raised an error):
# ArgumentError (missing keyword: :numbers)
```

[⬆️ Back to Top](#table-of-contents-)

### Is there some feature to auto handle exceptions inside of services/pipelines?

Answer: Yes, there is!

**Service objects:**

Like `Micro::Case::Strict` the `Micro::Case::Safe` is another kind of service object. It has the ability to intercept an exception as a failure result. e.g:

```ruby
require 'logger'

AppLogger = Logger.new(STDOUT)

class Divide < Micro::Case::Safe
  attributes :a, :b

  def call!
    return Success(a / b) if a.is_a?(Integer) && b.is_a?(Integer)
    Failure(:not_an_integer)
  end
end

result = Divide.call(a: 2, b: 0)
result.type == :exception             # true
result.value.is_a?(ZeroDivisionError) # true

result.on_failure(:exception) do |exception|
  AppLogger.error(exception.message) # E, [2019-08-21T00:05:44.195506 #9532] ERROR -- : divided by 0
end

# Note:
# ----
# If you need to handle a specific error,
# I recommend the usage of a case statement. e,g:

result.on_failure(:exception) do |exception, service|
  case exception
  when ZeroDivisionError then AppLogger.error(exception.message)
  else AppLogger.debug("#{service.class.name} was the service responsible for the exception")
  end
end

# Another note:
# ------------
# It is possible to rescue an exception even when is a safe service.
# Examples: https://github.com/serradura/u-service/blob/a6d0a8aa5d28d1f062484eaa0d5a17c4fb08b6fb/test/micro/case/safe_test.rb#L95-L123
```

**Pipelines:**

As the safe services, safe pipelines have the ability to intercept an exception in any of its steps. These are the ways to define one:

```ruby
module Users
  Create = ProcessParams & ValidateParams & Persist & SendToCRM
end

# Note:
# The ampersand is based on the safe navigation operator. https://ruby-doc.org/core-2.6/doc/syntax/calling_methods_rdoc.html#label-Safe+navigation+operator

# The alternatives are:

module Users
  class Create
    include Micro::Case::Pipeline::Safe

    pipeline ProcessParams, ValidateParams, Persist, SendToCRM
  end
end

# or

module Users
  Create = Micro::Case::Pipeline::Safe[
    ProcessParams,
    ValidateParams,
    Persist,
    SendToCRM
  ]
end
```

[⬆️ Back to Top](#table-of-contents-)

### How to validate service object attributes?

**Requirement:**

To do this your application must have the [activemodel >= 3.2](https://rubygems.org/gems/activemodel) as a dependency.

```ruby
#
# By default, if your application has the activemodel as a dependency,
# any kind of service can use it to validate their attributes.
#
class Multiply < Micro::Case::Base
  attributes :a, :b

  validates :a, :b, presence: true, numericality: true

  def call!
    return Failure(:validation_error) { self.errors } unless valid?

    Success(number: a * b)
  end
end

#
# But if do you want an automatic way to fail
# your services on validation errors, you can use:

# In some file. e.g: A Rails initializer
require 'micro/case/with_validation' # or require 'u-case/with_validation'

# In the Gemfile
gem 'u-case', require: 'u-case/with_validation'

# Using this approach, you can rewrite the previous example with fewer lines of code. e.g:

class Multiply < Micro::Case::Base
  attributes :a, :b

  validates :a, :b, presence: true, numericality: true

  def call!
    Success(number: a * b)
  end
end

# Note:
# ----
# After requiring the validation mode, the
# Micro::Case::Strict and Micro::Case::Safe classes will inherit this new behavior.
```

[⬆️ Back to Top](#table-of-contents-)

### Examples

1. [Rescuing an exception inside of service objects](https://github.com/serradura/u-service/blob/master/examples/rescuing_exceptions.rb)
2. [Users creation](https://github.com/serradura/u-service/blob/master/examples/users_creation.rb)

    An example of how to use services pipelines to sanitize and validate the input data, and how to represents a common use case, like: create an user.
3. [CLI calculator](https://github.com/serradura/u-service/tree/master/examples/calculator)

    A more complex example which use rake tasks to demonstrate how to handle user data, and how to use different failures type to control the app flow.

[⬆️ Back to Top](#table-of-contents-)

## Comparisons

Check it out implementations of the same use case with different libs (abstractions).

* [interactor](https://github.com/serradura/u-service/blob/master/comparisons/interactor.rb)
* [u-service](https://github.com/serradura/u-service/blob/master/comparisons/u-service.rb)

## Benchmarks

**[interactor](https://github.com/collectiveidea/interactor)** VS **[u-service](https://github.com/serradura/u-service)**

https://github.com/serradura/u-service/tree/master/benchmarks/interactor

![interactor VS u-service](https://github.com/serradura/u-service/blob/master/assets/u-service_benchmarks.png?raw=true)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `./test.sh` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/serradura/u-service. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Micro::Case project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/serradura/u-service/blob/master/CODE_OF_CONDUCT.md).
