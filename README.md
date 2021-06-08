<p align="center">
  <img src="./assets/ucase_logo_v1.png" alt="u-case - Represent use cases in a simple and powerful way while writing modular, expressive and sequentially logical code.">

  <p align="center"><i>Represent use cases in a simple and powerful way while writing modular, expressive and sequentially logical code.</i></p>
  <br>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/ruby->%3D%202.2.0-ruby.svg?colorA=99004d&colorB=cc0066" alt="Ruby">

  <a href="https://rubygems.org/gems/u-case">
    <img alt="Gem" src="https://img.shields.io/gem/v/u-case.svg?style=flat-square">
  </a>

  <a href="https://travis-ci.com/serradura/u-case">
    <img alt="Build Status" src="https://travis-ci.com/serradura/u-case.svg?branch=main">
  </a>

  <a href="https://codeclimate.com/github/serradura/u-case/maintainability">
    <img alt="Maintainability" src="https://api.codeclimate.com/v1/badges/5c3c8ad1b0b943f88efd/maintainability">
  </a>

  <a href="https://codeclimate.com/github/serradura/u-case/test_coverage">
    <img alt="Test Coverage" src="https://api.codeclimate.com/v1/badges/5c3c8ad1b0b943f88efd/test_coverage">
  </a>
</p>

The main project goals are:
1. Easy to use and easy to learn (input **>>** process **>>** output).
2. Promote immutability (transforming data instead of modifying it) and data integrity.
3. No callbacks (ex: before, after, around) to avoid code indirections that could compromise the state and understanding of application flows.
4. Solve complex business logic, by allowing the composition of use cases (flow creation).
5. Be fast and optimized (Check out the [benchmarks](#benchmarks) section).

> **Note:** Check out the repo https://github.com/serradura/from-fat-controllers-to-use-cases to see a Rails application that uses this gem to handle its business logic.

## Documentation <!-- omit in toc -->

Version   | Documentation
--------- | -------------
unreleased| https://github.com/serradura/u-case/blob/main/README.md
4.5.0     | https://github.com/serradura/u-case/blob/v4.x/README.md
3.1.0     | https://github.com/serradura/u-case/blob/v3.x/README.md
2.6.0     | https://github.com/serradura/u-case/blob/v2.x/README.md
1.1.0     | https://github.com/serradura/u-case/blob/v1.x/README.md

> **Note:** Você entende português? 🇧🇷&nbsp;🇵🇹 Verifique o [README traduzido em pt-BR](https://github.com/serradura/u-case/blob/main/README.pt-BR.md).

## Table of Contents <!-- omit in toc -->
- [Compatibility](#compatibility)
- [Dependencies](#dependencies)
- [Installation](#installation)
- [Usage](#usage)
  - [`Micro::Case` - How to define a use case?](#microcase---how-to-define-a-use-case)
  - [`Micro::Case::Result` - What is a use case result?](#microcaseresult---what-is-a-use-case-result)
    - [What are the default result types?](#what-are-the-default-result-types)
    - [How to define custom result types?](#how-to-define-custom-result-types)
    - [Is it possible to define a custom type without a result data?](#is-it-possible-to-define-a-custom-type-without-a-result-data)
    - [How to use the result hooks?](#how-to-use-the-result-hooks)
    - [Why the hook usage without a defined type exposes the result itself?](#why-the-hook-usage-without-a-defined-type-exposes-the-result-itself)
      - [Using decomposition to access the result data and type](#using-decomposition-to-access-the-result-data-and-type)
    - [What happens if a result hook was declared multiple times?](#what-happens-if-a-result-hook-was-declared-multiple-times)
    - [How to use the `Micro::Case::Result#then` method?](#how-to-use-the-microcaseresultthen-method)
      - [What does happens when a `Micro::Case::Result#then` receives a block?](#what-does-happens-when-a-microcaseresultthen-receives-a-block)
      - [How to make attributes data injection using this feature?](#how-to-make-attributes-data-injection-using-this-feature)
  - [`Micro::Cases::Flow` - How to compose use cases?](#microcasesflow---how-to-compose-use-cases)
    - [Is it possible to compose a flow with other flows?](#is-it-possible-to-compose-a-flow-with-other-flows)
    - [Is it possible a flow accumulates its input and merges each success result to use as the argument of the next use cases?](#is-it-possible-a-flow-accumulates-its-input-and-merges-each-success-result-to-use-as-the-argument-of-the-next-use-cases)
    - [How to understand what is happening during a flow execution?](#how-to-understand-what-is-happening-during-a-flow-execution)
      - [`Micro::Case::Result#transitions` schema](#microcaseresulttransitions-schema)
      - [Is it possible disable the `Micro::Case::Result#transitions`?](#is-it-possible-disable-the-microcaseresulttransitions)
    - [Is it possible to declare a flow that includes the use case itself as a step?](#is-it-possible-to-declare-a-flow-that-includes-the-use-case-itself-as-a-step)
  - [`Micro::Case::Strict` - What is a strict use case?](#microcasestrict---what-is-a-strict-use-case)
  - [`Micro::Case::Safe` - Is there some feature to auto handle exceptions inside of a use case or flow?](#microcasesafe---is-there-some-feature-to-auto-handle-exceptions-inside-of-a-use-case-or-flow)
    - [`Micro::Cases::Safe::Flow`](#microcasessafeflow)
    - [`Micro::Case::Result#on_exception`](#microcaseresulton_exception)
  - [`u-case/with_activemodel_validation` - How to validate the use case attributes?](#u-casewith_activemodel_validation---how-to-validate-the-use-case-attributes)
    - [If I enabled the auto validation, is it possible to disable it only in specific use cases?](#if-i-enabled-the-auto-validation-is-it-possible-to-disable-it-only-in-specific-use-cases)
    - [`Kind::Validator`](#kindvalidator)
- [`Micro::Case.config`](#microcaseconfig)
- [Benchmarks](#benchmarks)
  - [`Micro::Case`](#microcase)
    - [Success results](#success-results)
    - [Failure results](#failure-results)
  - [`Micro::Cases::Flow`](#microcasesflow)
  - [Running the benchmarks](#running-the-benchmarks)
    - [Performance (Benchmarks IPS)](#performance-benchmarks-ips)
    - [Memory profiling](#memory-profiling)
  - [Comparisons](#comparisons)
- [Examples](#examples)
  - [1️⃣ Users creation](#1️⃣-users-creation)
  - [2️⃣ Rails App (API)](#2️⃣-rails-app-api)
  - [3️⃣ CLI calculator](#3️⃣-cli-calculator)
  - [4️⃣ Rescuing exceptions inside of the use cases](#4️⃣-rescuing-exceptions-inside-of-the-use-cases)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)
- [Code of Conduct](#code-of-conduct)

## Compatibility

| u-case         | branch  | ruby     | activemodel   | u-attributes  |
| -------------- | ------- | -------- | ------------- | ------------- |
| unreleased     | main    | >= 2.2.0 | >= 3.2, < 7.0 | >= 2.7, < 3.0 |
| 4.5.0          | v4.x    | >= 2.2.0 | >= 3.2, < 7.0 | >= 2.7, < 3.0 |
| 3.1.0          | v3.x    | >= 2.2.0 | >= 3.2, < 6.1 |        ~> 1.1 |
| 2.6.0          | v2.x    | >= 2.2.0 | >= 3.2, < 6.1 |        ~> 1.1 |
| 1.1.0          | v1.x    | >= 2.2.0 | >= 3.2, < 6.1 |        ~> 1.1 |

> Note: The activemodel is an optional dependency, this module [can be enabled](#u-casewith_activemodel_validation---how-to-validate-use-case-attributes) to validate the use cases' attributes.

## Dependencies

1. [`kind`](https://github.com/serradura/kind) gem.

    A simple type system (at runtime) for Ruby.

    It is used to validate some internal u-case's methods input. This gem also exposes an  [`ActiveModel validator`](https://github.com/serradura/kind#kindvalidator-activemodelvalidations) when requiring the [`u-case/with_activemodel_validation`](#u-casewith_activemodel_validation---how-to-validate-use-case-attributes) module, or when the [`Micro::Case.config`](#microcaseconfig) was used to enable it.
2. [`u-attributes`](https://github.com/serradura/u-attributes) gem.

    This gem allows defining read-only attributes, that is, your objects will have only getters to access their attributes data.
    It is used to define the use case attributes.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'u-case', '~> 4.5.0'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install u-case

## Usage

### `Micro::Case` - How to define a use case?

```ruby
class Multiply < Micro::Case
  # 1. Define its input as attributes
  attributes :a, :b

  # 2. Define the method `call!` with its business logic
  def call!

    # 3. Wrap the use case output using the `Success(result: *)` or `Failure(result: *)` methods
    if a.is_a?(Numeric) && b.is_a?(Numeric)
      Success result: { number: a * b }
    else
      Failure result: { message: '`a` and `b` attributes must be numeric' }
    end
  end
end

#========================#
# Performing an use case #
#========================#

# Success result

result = Multiply.call(a: 2, b: 2)

result.success? # true
result.data     # { number: 4 }

# Failure result

bad_result = Multiply.call(a: 2, b: '2')

bad_result.failure? # true
bad_result.data     # { message: "`a` and `b` attributes must be numeric" }

# Note:
# ----
# The result of a Micro::Case.call is an instance of Micro::Case::Result
```

[⬆️ Back to Top](#table-of-contents-)

### `Micro::Case::Result` - What is a use case result?

A `Micro::Case::Result` stores the use cases output data. These are their main methods:
- `#success?` returns true if is a successful result.
- `#failure?` returns true if is an unsuccessful result.
- `#use_case` returns the use case responsible for it. This feature is handy to handle a flow failure (this topic will be covered ahead).
- `#type` a Symbol which gives meaning for the result, this is useful to declare different types of failures or success.
- `#data` the result data itself.
- `#[]` and `#values_at` are shortcuts to access the `#data` values.
- `#key?` returns `true` if the key is present in `#data`.
- `#value?` returns `true` if the given value is present in `#data`.
- `#slice` returns a new hash that includes only the given keys. If the given keys don't exist, an empty hash is returned.
- `#on_success` or `#on_failure` are hook methods that help you to define the application flow.
- `#then` this method will allow applying a new use case if the current result was a success. The idea of this feature is to allow the creation of dynamic flows.
- `#transitions` returns an array with all of transformations wich a result [has during a flow](#how-to-understand-what-is-happening-during-a-flow-execution).

> **Note:** for backward compatibility, you could use the `#value` method as an alias of `#data` method.

[⬆️ Back to Top](#table-of-contents-)

#### What are the default result types?

Every result has a type, and these are their default values:
- `:ok` when success
- `:error` or `:exception` when failures

```ruby
class Divide < Micro::Case
  attributes :a, :b

  def call!
    if invalid_attributes.empty?
      Success result: { number: a / b }
    else
      Failure result: { invalid_attributes: invalid_attributes }
    end
  rescue => exception
    Failure result: exception
  end

  private def invalid_attributes
    attributes.select { |_key, value| !value.is_a?(Numeric) }
  end
end

# Success result

result = Divide.call(a: 2, b: 2)

result.type     # :ok
result.data     # { number: 1 }
result.success? # true
result.use_case # #<Divide:0x0000 @__attributes={"a"=>2, "b"=>2}, @a=2, @b=2, @__result=...>

# Failure result (type == :error)

bad_result = Divide.call(a: 2, b: '2')

bad_result.type     # :error
bad_result.data     # { invalid_attributes: { "b"=>"2" } }
bad_result.failure? # true
bad_result.use_case # #<Divide:0x0000 @__attributes={"a"=>2, "b"=>"2"}, @a=2, @b="2", @__result=...>

# Failure result (type == :exception)

err_result = Divide.call(a: 2, b: 0)

err_result.type     # :exception
err_result.data     # { exception: <ZeroDivisionError: divided by 0> }
err_result.failure? # true
err_result.use_case # #<Divide:0x0000 @__attributes={"a"=>2, "b"=>0}, @a=2, @b=0, @__result=#<Micro::Case::Result:0x0000 @use_case=#<Divide:0x0000 ...>, @type=:exception, @value=#<ZeroDivisionError: divided by 0>, @success=false>

# Note:
# ----
# Any Exception instance which is wrapped by
# the Failure(result: *) method will receive `:exception` instead of the `:error` type.
```

[⬆️ Back to Top](#table-of-contents-)

#### How to define custom result types?

Answer: Use a symbol as the argument of `Success()`, `Failure()` methods and declare the `result:` keyword to set the result data.

```ruby
class Multiply < Micro::Case
  attributes :a, :b

  def call!
    if a.is_a?(Numeric) && b.is_a?(Numeric)
      Success result: { number: a * b }
    else
      Failure :invalid_data, result: {
        attributes: attributes.reject { |_, input| input.is_a?(Numeric) }
      }
    end
  end
end

# Success result

result = Multiply.call(a: 3, b: 2)

result.type     # :ok
result.data     # { number: 6 }
result.success? # true

# Failure result

bad_result = Multiply.call(a: 3, b: '2')

bad_result.type     # :invalid_data
bad_result.data     # { attributes: {"b"=>"2"} }
bad_result.failure? # true
```

[⬆️ Back to Top](#table-of-contents-)

#### Is it possible to define a custom type without a result data?

Answer: Yes, it is possible. But this will have special behavior because the result data will be a hash with the given type as the key and `true` as its value.

```ruby
class Multiply < Micro::Case
  attributes :a, :b

  def call!
    if a.is_a?(Numeric) && b.is_a?(Numeric)
      Success result: { number: a * b }
    else
      Failure(:invalid_data)
    end
  end
end

result = Multiply.call(a: 2, b: '2')

result.failure?            # true
result.data                # { :invalid_data => true }
result.type                # :invalid_data
result.use_case.attributes # {"a"=>2, "b"=>"2"}

# Note:
# ----
# This feature is handy to handle failures in a flow
# (this topic will be covered ahead).
```

[⬆️ Back to Top](#table-of-contents-)

#### How to use the result hooks?

As [mentioned earlier](#microcaseresult---what-is-a-use-case-result), the `Micro::Case::Result` has two methods to improve the application flow control. They are: `#on_success`, `on_failure`.

The examples below show how to use them:

```ruby
class Double < Micro::Case
  attribute :number

  def call!
    return Failure :invalid, result: { msg: 'number must be a numeric value' } unless number.is_a?(Numeric)
    return Failure :lte_zero, result: { msg: 'number must be greater than 0' } if number <= 0

    Success result: { number: number * 2 }
  end
end

#================================#
# Printing the output if success #
#================================#

Double
  .call(number: 3)
  .on_success { |result| p result[:number] }
  .on_failure(:invalid) { |result| raise TypeError, result[:msg] }
  .on_failure(:lte_zero) { |result| raise ArgumentError, result[:msg] }

# The output will be:
#   6

#=============================#
# Raising an error if failure #
#=============================#

Double
  .call(number: -1)
  .on_success { |result| p result[:number] }
  .on_failure { |_result, use_case| puts "#{use_case.class.name} was the use case responsible for the failure" }
  .on_failure(:invalid) { |result| raise TypeError, result[:msg] }
  .on_failure(:lte_zero) { |result| raise ArgumentError, result[:msg] }

# The outputs will be:
#
# 1. It will print the message: Double was the use case responsible for the failure
# 2. It will raise the exception: ArgumentError (the number must be greater than 0)

# Note:
# ----
# The use case responsible for the result will always be accessible as the second hook argument
```

#### Why the hook usage without a defined type exposes the result itself?

Answer: To allow you to define how to handle the program flow using some conditional statement like an `if` or `case when`.

```ruby
class Double < Micro::Case
  attribute :number

  def call!
    return Failure(:invalid) unless number.is_a?(Numeric)
    return Failure :lte_zero, result: attributes(:number) if number <= 0

    Success result: { number: number * 2 }
  end
end

Double
  .call(number: -1)
  .on_failure do |result, use_case|
    case result.type
    when :invalid then raise TypeError, "number must be a numeric value"
    when :lte_zero then raise ArgumentError, "number `#{result[:number]}` must be greater than 0"
    else raise NotImplementedError
    end
  end

# The output will be an exception:
#
# ArgumentError (number `-1` must be greater than 0)
```

> **Note:** The same that was did in the previous examples could be done with `#on_success` hook!

##### Using decomposition to access the result data and type

The syntax to decompose an Array can be used in assignments and in method/block arguments.
If you doesn't know it, check out the [Ruby doc](https://ruby-doc.org/core-2.2.0/doc/syntax/assignment_rdoc.html#label-Array+Decomposition).

```ruby
# The object exposed in the hook without a type is a Micro::Case::Result and it can be decomposed. e.g:

Double
  .call(number: -2)
  .on_failure do |(data, type), use_case|
    case type
    when :invalid then raise TypeError, 'number must be a numeric value'
    when :lte_zero then raise ArgumentError, "number `#{data[:number]}` must be greater than 0"
    else raise NotImplementedError
    end
  end

# The output will be the exception:
#
# ArgumentError (the number `-2` must be greater than 0)
```

> **Note:** The same that was did in the previous examples could be done with `#on_success` hook!

[⬆️ Back to Top](#table-of-contents-)

#### What happens if a result hook was declared multiple times?

Answer: The hook always will be triggered if it matches the result type.

```ruby
class Double < Micro::Case
  attributes :number

  def call!
    if number.is_a?(Numeric)
      Success :computed, result: { number: number * 2 }
    else
      Failure :invalid, result: { msg: 'number must be a numeric value' }
    end
  end
end

result = Double.call(number: 3)
result.data         # { number: 6 }
result[:number] * 4 # 24

accum = 0

result
  .on_success { |result| accum += result[:number] }
  .on_success { |result| accum += result[:number] }
  .on_success(:computed) { |result| accum += result[:number] }
  .on_success(:computed) { |result| accum += result[:number] }

accum # 24

result[:number] * 4 == accum # true
```

#### How to use the `Micro::Case::Result#then` method?

This method allows you to create dynamic flows, so, with it, you can add new use cases or flows to continue the result transformation. e.g:

```ruby
class ForbidNegativeNumber < Micro::Case
  attribute :number

  def call!
    return Success result: attributes if number >= 0

    Failure result: attributes
  end
end

class Add3 < Micro::Case
  attribute :number

  def call!
    Success result: { number: number + 3 }
  end
end

result1 =
  ForbidNegativeNumber
    .call(number: -1)
    .then(Add3)

result1.data    # {'number' => -1}
result1.failure? # true

# ---

result2 =
  ForbidNegativeNumber
    .call(number: 1)
    .then(Add3)

result2.data     # {'number' => 4}
result2.success? # true
```

> **Note:** this method changes the [`Micro::Case::Result#transitions`](#how-to-understand-what-is-happening-during-a-flow-execution).

[⬆️ Back to Top](#table-of-contents-)

##### What does happens when a `Micro::Case::Result#then` receives a block?

It will yields self (a `Micro::Case::Result` instance) to the block, and will return the output of the block instead of itself. e.g:

```ruby
class Add < Micro::Case
  attributes :a, :b

  def call!
    if Kind.of?(Numeric, a, b)
      Success result: { sum: a + b }
    else
      Failure(:attributes_arent_numbers)
    end
  end
end

# --

success_result =
  Add
    .call(a: 2, b: 2)
    .then { |result| result.success? ? result[:sum] : 0 }

puts success_result # 4

# --

failure_result =
  Add
    .call(a: 2, b: '2')
    .then { |result| result.success? ? result[:sum] : 0 }

puts failure_result # 0
```

[⬆️ Back to Top](#table-of-contents-)

##### How to make attributes data injection using this feature?

Pass a Hash as the second argument of the `Micro::Case::Result#then` method.

```ruby
Todo::FindAllForUser
  .call(user: current_user, params: params)
  .then(Paginate)
  .then(Serialize::PaginatedRelationAsJson, serializer: Todo::Serializer)
  .on_success { |result| render_json(200, data: result[:todos]) }
```

[⬆️ Back to Top](#table-of-contents-)

### `Micro::Cases::Flow` - How to compose use cases?

We call as **flow** a composition of use cases. The main idea of this feature is to use/reuse use cases as steps of a new use case. e.g.

```ruby
module Steps
  class ConvertTextToNumbers < Micro::Case
    attribute :numbers

    def call!
      if numbers.all? { |value| String(value) =~ /\d+/ }
        Success result: { numbers: numbers.map(&:to_i) }
      else
        Failure result: { message: 'numbers must contain only numeric types' }
      end
    end
  end

  class Add2 < Micro::Case::Strict
    attribute :numbers

    def call!
      Success result: { numbers: numbers.map { |number| number + 2 } }
    end
  end

  class Double < Micro::Case::Strict
    attribute :numbers

    def call!
      Success result: { numbers: numbers.map { |number| number * 2 } }
    end
  end

  class Square < Micro::Case::Strict
    attribute :numbers

    def call!
      Success result: { numbers: numbers.map { |number| number * number } }
    end
  end
end

#-------------------------------------------#
# Creating a flow using Micro::Cases.flow() #
#-------------------------------------------#

Add2ToAllNumbers = Micro::Cases.flow([
  Steps::ConvertTextToNumbers,
  Steps::Add2
])

result = Add2ToAllNumbers.call(numbers: %w[1 1 2 2 3 4])

result.success? # true
result.data    # {:numbers => [3, 3, 4, 4, 5, 6]}

#-------------------------------#
# Creating a flow using classes #
#-------------------------------#

class DoubleAllNumbers < Micro::Case
  flow Steps::ConvertTextToNumbers,
       Steps::Double
end

DoubleAllNumbers.
  call(numbers: %w[1 1 b 2 3 4]).
  on_failure { |result| puts result[:message] } # "numbers must contain only numeric types"
```

When happening a failure, the use case responsible will be accessible in the result.

```ruby
result = DoubleAllNumbers.call(numbers: %w[1 1 b 2 3 4])

result.failure?                                    # true
result.use_case.is_a?(Steps::ConvertTextToNumbers) # true

result.on_failure do |_message, use_case|
  puts "#{use_case.class.name} was the use case responsible for the failure" # Steps::ConvertTextToNumbers was the use case responsible for the failure
end
```

[⬆️ Back to Top](#table-of-contents-)

#### Is it possible to compose a flow with other flows?

Answer: Yes, it is possible.

```ruby
module Steps
  class ConvertTextToNumbers < Micro::Case
    attribute :numbers

    def call!
      if numbers.all? { |value| String(value) =~ /\d+/ }
        Success result: { numbers: numbers.map(&:to_i) }
      else
        Failure result: { message: 'numbers must contain only numeric types' }
      end
    end
  end

  class Add2 < Micro::Case::Strict
    attribute :numbers

    def call!
      Success result: { numbers: numbers.map { |number| number + 2 } }
    end
  end

  class Double < Micro::Case::Strict
    attribute :numbers

    def call!
      Success result: { numbers: numbers.map { |number| number * 2 } }
    end
  end

  class Square < Micro::Case::Strict
    attribute :numbers

    def call!
      Success result: { numbers: numbers.map { |number| number * number } }
    end
  end
end

DoubleAllNumbers =
  Micro::Cases.flow([Steps::ConvertTextToNumbers, Steps::Double])

SquareAllNumbers =
  Micro::Cases.flow([Steps::ConvertTextToNumbers, Steps::Square])

DoubleAllNumbersAndAdd2 =
  Micro::Cases.flow([DoubleAllNumbers, Steps::Add2])

SquareAllNumbersAndAdd2 =
  Micro::Cases.flow([SquareAllNumbers, Steps::Add2])

SquareAllNumbersAndDouble =
  Micro::Cases.flow([SquareAllNumbersAndAdd2, DoubleAllNumbers])

DoubleAllNumbersAndSquareAndAdd2 =
  Micro::Cases.flow([DoubleAllNumbers, SquareAllNumbersAndAdd2])

SquareAllNumbersAndDouble
  .call(numbers: %w[1 1 2 2 3 4])
  .on_success { |result| p result[:numbers] } # [6, 6, 12, 12, 22, 36]

DoubleAllNumbersAndSquareAndAdd2
  .call(numbers: %w[1 1 2 2 3 4])
  .on_success { |result| p result[:numbers] } # [6, 6, 18, 18, 38, 66]
```

> **Note:** You can blend any [approach](#microcasesflow---how-to-compose-use-cases) to create use case flows - [examples](https://github.com/serradura/u-case/blob/714c6b658fc6aa02617e6833ddee09eddc760f2a/test/micro/cases/flow/blend_test.rb#L5-L35).

[⬆️ Back to Top](#table-of-contents-)

#### Is it possible a flow accumulates its input and merges each success result to use as the argument of the next use cases?

Answer: Yes, it is possible! Look at the example below to understand how the data accumulation works inside of a flow execution.

```ruby
module Users
  class FindByEmail < Micro::Case
    attribute :email

    def call!
      user = User.find_by(email: email)

      return Success result: { user: user } if user

      Failure(:user_not_found)
    end
  end
end

module Users
  class ValidatePassword < Micro::Case::Strict
    attributes :user, :password

    def call!
      return Failure(:user_must_be_persisted) if user.new_record?
      return Failure(:wrong_password) if user.wrong_password?(password)

      return Success result: attributes(:user)
    end
  end
end

module Users
  Authenticate = Micro::Cases.flow([
    FindByEmail,
    ValidatePassword
  ])
end

Users::Authenticate
  .call(email: 'somebody@test.com', password: 'password')
  .on_success { |result| sign_in(result[:user]) }
  .on_failure(:wrong_password) { render status: 401 }
  .on_failure(:user_not_found) { render status: 404 }
```

First, let's see the attributes used by each use case:

```ruby
class Users::FindByEmail < Micro::Case
  attribute :email
end

class Users::ValidatePassword < Micro::Case
  attributes :user, :password
end
```

As you can see the `Users::ValidatePassword` expects a user as its input. So, how does it receives the user?
Answer: It receives the user from the `Users::FindByEmail` success result!

And this is the power of use cases composition because the output of one step will compose the input of the next use case in the flow!

> input **>>** process **>>** output

> **Note:** Check out these test examples [Micro::Cases::Flow](https://github.com/serradura/u-case/blob/c96a3650469da40dc9f83ff678204055b7015d01/test/micro/cases/flow/result_transitions_test.rb) and [Micro::Cases::Safe::Flow](https://github.com/serradura/u-case/blob/c96a3650469da40dc9f83ff678204055b7015d01/test/micro/cases/safe/flow/result_transitions_test.rb) to see different use cases having access to the data in a flow.

[⬆️ Back to Top](#table-of-contents-)

#### How to understand what is happening during a flow execution?

Use `Micro::Case::Result#transitions`!

Let's use the [previous section example](#is-it-possible-a-flow-accumulates-its-input-and-merges-each-success-result-to-use-as-the-argument-of-the-next-use-cases) to ilustrate how to use this feature.

```ruby
user_authenticated =
  Users::Authenticate.call(email: 'rodrigo@test.com', password: user_password)

user_authenticated.transitions
[
  {
    :use_case => {
      :class      => Users::FindByEmail,
      :attributes => { :email => "rodrigo@test.com" }
    },
    :success => {
      :type  => :ok,
      :result => {
        :user => #<User:0x00007fb57b1c5f88 @email="rodrigo@test.com" ...>
      }
    },
    :accessible_attributes => [ :email, :password ]
  },
  {
    :use_case => {
      :class      => Users::ValidatePassword,
      :attributes => {
        :user     => #<User:0x00007fb57b1c5f88 @email="rodrigo@test.com" ...>
        :password => "123456"
      }
    },
    :success => {
      :type  => :ok,
      :result => {
        :user => #<User:0x00007fb57b1c5f88 @email="rodrigo@test.com" ...>
      }
    },
    :accessible_attributes => [ :email, :password, :user ]
  }
]
```

The example above shows the output generated by the `Micro::Case::Result#transitions`.
With it is possible to analyze the use cases' execution order and what were the given `inputs` (`[:attributes]`) and `outputs` (`[:success][:result]`) in the entire execution.

And look up the `accessible_attributes` property, it shows whats attributes are accessible in that flow step. For example, in the last step, you can see that the `accessible_attributes` increased because of the [data flow accumulation](#is-it-possible-a-flow-accumulates-its-input-and-merges-each-success-result-to-use-as-the-argument-of-the-next-use-cases).

> **Note:** The [`Micro::Case::Result#then`](#how-to-use-the-microcaseresultthen-method) increments the `Micro::Case::Result#transitions`.

##### `Micro::Case::Result#transitions` schema
```ruby
[
  {
    use_case: {
      class:      <Micro::Case>,# Use case which was executed
      attributes: <Hash>        # (Input) The use case's attributes
    },
    [success:, failure:] => {   # (Output)
      type:  <Symbol>,          # Result type. Defaults:
                                # Success = :ok, Failure = :error/:exception
      result: <Hash>            # The data returned by the use case result
    },
    accessible_attributes: <Array>, # Properties that can be accessed by the use case's attributes,
                                    # it starts with Hash used to invoke it and that will be incremented
                                    # with the result values of each use case in the flow.
  }
]
```

##### Is it possible disable the `Micro::Case::Result#transitions`?

Answer: Yes, it is! You can use the `Micro::Case.config` to do this. [Link to](#microcaseconfig) this section.

#### Is it possible to declare a flow that includes the use case itself as a step?

Answer: Yes, it is! You can use `self` or the `self.call!` macro. e.g:

```ruby
class ConvertTextToNumber < Micro::Case
  attribute :text

  def call!
    Success result: { number: text.to_i }
  end
end

class ConvertNumberToText < Micro::Case
  attribute :number

  def call!
    Success result: { text: number.to_s }
  end
end

class Double < Micro::Case
  flow ConvertTextToNumber,
       self.call!,
       ConvertNumberToText

  attribute :number

  def call!
    Success result: { number: number * 2 }
  end
end

result = Double.call(text: '4')

result.success? # true
result[:number] # "8"
```

> **Note:** This feature can be used with the Micro::Case::Safe. Checkout this test to see an example: https://github.com/serradura/u-case/blob/714c6b658fc6aa02617e6833ddee09eddc760f2a/test/micro/case/safe/with_inner_flow_test.rb

[⬆️ Back to Top](#table-of-contents-)

### `Micro::Case::Strict` - What is a strict use case?

Answer: it is a kind of use case that will require all the keywords (attributes) on its initialization.

```ruby
class Double < Micro::Case::Strict
  attribute :numbers

  def call!
    Success result: { numbers: numbers.map { |number| number * 2 } }
  end
end

Double.call({})

# The output will be:
# ArgumentError (missing keyword: :numbers)
```

[⬆️ Back to Top](#table-of-contents-)

### `Micro::Case::Safe` - Is there some feature to auto handle exceptions inside of a use case or flow?

Yes, there is one! Like `Micro::Case::Strict` the `Micro::Case::Safe` is another kind of use case. It has the ability to auto intercept any exception as a failure result. e.g:

```ruby
require 'logger'

AppLogger = Logger.new(STDOUT)

class Divide < Micro::Case::Safe
  attributes :a, :b

  def call!
    if a.is_a?(Integer) && b.is_a?(Integer)
      Success result: { number: a / b}
    else
      Failure(:not_an_integer)
    end
  end
end

result = Divide.call(a: 2, b: 0)
result.type == :exception                   # true
result.data                                 # { exception: #<ZeroDivisionError...> }
result[:exception].is_a?(ZeroDivisionError) # true

result.on_failure(:exception) do |result|
  AppLogger.error(result[:exception].message) # E, [2019-08-21T00:05:44.195506 #9532] ERROR -- : divided by 0
end
```

If you need to handle a specific error, I recommend the usage of a case statement. e,g:

```ruby
result.on_failure(:exception) do |data, use_case|
  case exception = data[:exception]
  when ZeroDivisionError then AppLogger.error(exception.message)
  else AppLogger.debug("#{use_case.class.name} was the use case responsible for the exception")
  end
end
```

> **Note:** It is possible to rescue an exception even when is a safe use case. Examples: https://github.com/serradura/u-case/blob/714c6b658fc6aa02617e6833ddee09eddc760f2a/test/micro/case/safe_test.rb#L90-L118

[⬆️ Back to Top](#table-of-contents-)

#### `Micro::Cases::Safe::Flow`

As the safe use cases, safe flows can intercept an exception in any of its steps. These are the ways to define one:

```ruby
module Users
  Create = Micro::Cases.safe_flow([
    ProcessParams,
    ValidateParams,
    Persist,
    SendToCRM
  ])
end
```

Defining within classes:

```ruby
module Users
  class Create < Micro::Case::Safe
    flow ProcessParams,
         ValidateParams,
         Persist,
         SendToCRM
  end
end
```

[⬆️ Back to Top](#table-of-contents-)

#### `Micro::Case::Result#on_exception`

In functional programming errors/exceptions are handled as regular data, the idea is to transform the output even when it happens an unexpected behavior. For many, [exceptions are very similar to the GOTO statement](https://softwareengineering.stackexchange.com/questions/189222/are-exceptions-as-control-flow-considered-a-serious-antipattern-if-so-why), jumping the application flow to paths which could be difficult to figure out how things work in a system.

To address this the `Micro::Case::Result` has a special hook `#on_exception` to helping you to handle the control flow in the case of exceptions.

> **Note**: this feature will work better if you use it with a `Micro::Case::Safe` flow or use case.

**How does it work?**

```ruby
class Divide < Micro::Case::Safe
  attributes :a, :b

  def call!
    Success result: { division: a / b }
  end
end

Divide
  .call(a: 2, b: 0)
  .on_success { |result| puts result[:division] }
  .on_exception(TypeError) { puts 'Please, use only numeric attributes.' }
  .on_exception(ZeroDivisionError) { |_error| puts "Can't divide a number by 0." }
  .on_exception { |_error, _use_case| puts 'Oh no, something went wrong!' }

# Output:
# -------
# Can't divide a number by 0
# Oh no, something went wrong!

Divide
  .call(a: 2, b: '2')
  .on_success { |result| puts result[:division] }
  .on_exception(TypeError) { puts 'Please, use only numeric attributes.' }
  .on_exception(ZeroDivisionError) { |_error| puts "Can't divide a number by 0." }
  .on_exception { |_error, _use_case| puts 'Oh no, something went wrong!' }

# Output:
# -------
# Please, use only numeric attributes.
# Oh no, something went wrong!
```

As you can see, this hook has the same behavior of `result.on_failure(:exception)`, but, the idea here is to have a better communication in the code, making an explicit reference when some failure happened because of an exception.

[⬆️ Back to Top](#table-of-contents-)

### `u-case/with_activemodel_validation` - How to validate the use case attributes?

**Requirement:**

To do this your application must have the [activemodel >= 3.2, < 6.1.0](https://rubygems.org/gems/activemodel) as a dependency.

By default, if your application has ActiveModel as a dependency, any kind of use case can make use of it to validate its attributes.

```ruby
class Multiply < Micro::Case
  attributes :a, :b

  validates :a, :b, presence: true, numericality: true

  def call!
    return Failure :invalid_attributes, result: { errors: self.errors } if invalid?

    Success result: { number: a * b }
  end
end
```

But if do you want an automatic way to fail your use cases on validation errors, you could do:

1. **require 'u-case/with_activemodel_validation'** in the Gemfile

  ```ruby
  gem 'u-case', require: 'u-case/with_activemodel_validation'
  ```

2. Use the `Micro::Case.config` to enable it. [Link to](#microcaseconfig) this section.

Using this approach, you can rewrite the previous example with less code. e.g:

```ruby
require 'u-case/with_activemodel_validation'

class Multiply < Micro::Case
  attributes :a, :b

  validates :a, :b, presence: true, numericality: true

  def call!
    Success result: { number: a * b }
  end
end
```

> **Note:** After requiring the validation mode, the `Micro::Case::Strict` and `Micro::Case::Safe` classes will inherit this new behavior.

#### If I enabled the auto validation, is it possible to disable it only in specific use cases?

Answer: Yes, it is possible. To do this, you will need to use the `disable_auto_validation` macro. e.g:

```ruby
require 'u-case/with_activemodel_validation'

class Multiply < Micro::Case
  disable_auto_validation

  attribute :a
  attribute :b
  validates :a, :b, presence: true, numericality: true

  def call!
    Success result: { number: a * b }
  end
end

Multiply.call(a: 2, b: 'a')

# The output will be:
# TypeError (String can't be coerced into Integer)
```

[⬆️ Back to Top](#table-of-contents-)

#### `Kind::Validator`

The [kind gem](https://github.com/serradura/kind) has a module to enable the validation of data type through [`ActiveModel validations`](https://guides.rubyonrails.org/active_model_basics.html#validations). So, when you require the `'u-case/with_activemodel_validation'`, this module will also require the [`Kind::Validator`](https://github.com/serradura/kind#kindvalidator-activemodelvalidations).

The example below shows how to validate the attributes types.

```ruby
class Todo::List::AddItem < Micro::Case
  attributes :user, :params

  validates :user, kind: User
  validates :params, kind: ActionController::Parameters

  def call!
    todo_params = params.require(:todo).permit(:title, :due_at)

    todo = user.todos.create(todo_params)

    Success result: { todo: todo }
  rescue ActionController::ParameterMissing => e
    Failure :parameter_missing, result: { message: e.message }
  end
end
```

[⬆️ Back to Top](#table-of-contents-)

## `Micro::Case.config`

The idea of this resource is to allow the configuration of some `u-case` features/modules.
I recommend you use it only once in your codebase. e.g. In a Rails initializer.

You can see below, which are the available configurations with their default values:

```ruby
Micro::Case.config do |config|
  # Use ActiveModel to auto-validate your use cases' attributes.
  config.enable_activemodel_validation = false

  # Use to enable/disable the `Micro::Case::Results#transitions`.
  config.enable_transitions = true
end
```

[⬆️ Back to Top](#table-of-contents-)

## Benchmarks

### `Micro::Case`

#### Success results

| Gem / Abstraction      | Iterations per second |       Comparison  |
| -----------------      | --------------------: | ----------------: |
| Dry::Monads            |              315635.1 | _**The Fastest**_ |
| **Micro::Case**        |               75837.7 |     4.16x slower  |
| Interactor             |               59745.5 |     5.28x slower  |
| Trailblazer::Operation |               28423.9 |    11.10x slower  |
| Dry::Transaction       |               10130.9 |    31.16x slower  |

<details>
  <summary>Show the full <a href="https://github.com/evanphx/benchmark-ips">benchmark/ips</a> results.</summary>

```ruby
# Warming up --------------------------------------
#           Interactor     5.711k i/100ms
# Trailblazer::Operation
#                          2.283k i/100ms
#          Dry::Monads    31.130k i/100ms
#     Dry::Transaction   994.000  i/100ms
#          Micro::Case     7.911k i/100ms
#    Micro::Case::Safe     7.911k i/100ms
#  Micro::Case::Strict     6.248k i/100ms

# Calculating -------------------------------------
#           Interactor     59.746k (±29.9%) i/s -    274.128k in   5.049901s
# Trailblazer::Operation
#                          28.424k (±15.8%) i/s -    141.546k in   5.087882s
#          Dry::Monads    315.635k (± 6.1%) i/s -      1.588M in   5.048914s
#     Dry::Transaction     10.131k (± 6.4%) i/s -     50.694k in   5.025150s
#          Micro::Case     75.838k (± 9.7%) i/s -    379.728k in   5.052573s
#    Micro::Case::Safe     75.461k (±10.1%) i/s -    379.728k in   5.079238s
#  Micro::Case::Strict     64.235k (± 9.0%) i/s -    324.896k in   5.097028s

# Comparison:
#          Dry::Monads:   315635.1 i/s
#          Micro::Case:    75837.7 i/s - 4.16x  (± 0.00) slower
#    Micro::Case::Safe:    75461.3 i/s - 4.18x  (± 0.00) slower
#  Micro::Case::Strict:    64234.9 i/s - 4.91x  (± 0.00) slower
#           Interactor:    59745.5 i/s - 5.28x  (± 0.00) slower
# Trailblazer::Operation:    28423.9 i/s - 11.10x  (± 0.00) slower
#     Dry::Transaction:    10130.9 i/s - 31.16x  (± 0.00) slower
```
</details>

https://github.com/serradura/u-case/blob/main/benchmarks/perfomance/use_case/success_results.rb

#### Failure results

| Gem / Abstraction      | Iterations per second |       Comparison  |
| -----------------      | --------------------: | ----------------: |
| Dry::Monads            |              135386.9 | _**The Fastest**_ |
| **Micro::Case**        |               73489.3 |     1.85x slower  |
| Trailblazer::Operation |               29016.4 |     4.67x slower  |
| Interactor             |               27037.0 |     5.01x slower  |
| Dry::Transaction       |                8988.6 |    15.06x slower  |

<details>
  <summary>Show the full <a href="https://github.com/evanphx/benchmark-ips">benchmark/ips</a> results.</summary>

```ruby
# Warming up --------------------------------------
#           Interactor     2.626k i/100ms
# Trailblazer::Operation   2.343k i/100ms
#          Dry::Monads    13.386k i/100ms
#     Dry::Transaction   868.000  i/100ms
#          Micro::Case     7.603k i/100ms
#    Micro::Case::Safe     7.598k i/100ms
#  Micro::Case::Strict     6.178k i/100ms

# Calculating -------------------------------------
#           Interactor     27.037k (±24.9%) i/s -    128.674k in   5.102133s
# Trailblazer::Operation   29.016k (±12.4%) i/s -    145.266k in   5.074991s
#          Dry::Monads    135.387k (±15.1%) i/s -    669.300k in   5.055356s
#     Dry::Transaction      8.989k (± 9.2%) i/s -     45.136k in   5.084820s
#          Micro::Case     73.247k (± 9.9%) i/s -    364.944k in   5.030449s
#    Micro::Case::Safe     73.489k (± 9.6%) i/s -    364.704k in   5.007282s
#  Micro::Case::Strict     61.980k (± 8.0%) i/s -    308.900k in   5.014821s

# Comparison:
#          Dry::Monads:   135386.9 i/s
#    Micro::Case::Safe:    73489.3 i/s - 1.84x  (± 0.00) slower
#          Micro::Case:    73246.6 i/s - 1.85x  (± 0.00) slower
#  Micro::Case::Strict:    61979.7 i/s - 2.18x  (± 0.00) slower
# Trailblazer::Operation:    29016.4 i/s - 4.67x  (± 0.00) slower
#           Interactor:    27037.0 i/s - 5.01x  (± 0.00) slower
#     Dry::Transaction:     8988.6 i/s - 15.06x  (± 0.00) slower
```
</details>

https://github.com/serradura/u-case/blob/main/benchmarks/perfomance/use_case/failure_results.rb

---

### `Micro::Cases::Flow`

| Gems / Abstraction      | [Success results](https://github.com/serradura/u-case/blob/main/benchmarks/perfomance/flow/success_results.rb) | [Failure results](https://github.com/serradura/u-case/blob/main/benchmarks/perfomance/flow/failure_results.rb) |
| ------------------------------------------- | ----------------: | ----------------: |
| Micro::Case::Result `pipe` method           |       80936.2 i/s |       78280.4 i/s |
| Micro::Case::Result `then` method           |         0x slower |         0x slower |
| Micro::Cases.flow                           |         0x slower |         0x slower |
| Micro::Case class with an inner flow        |      1.72x slower |      1.68x slower |
| Micro::Case class including itself as a step|      1.93x slower |      1.87x slower |
| Interactor::Organizer                       |      3.33x slower |      3.22x slower |

\* The `Dry::Monads`, `Dry::Transaction`, `Trailblazer::Operation` gems are out of this analysis because all of them doesn't have this kind of feature.

<details>
  <summary><strong>Success results</strong> - Show the full benchmark/ips results.</summary>

```ruby
# Warming up --------------------------------------
# Interactor::Organizer             1.809k i/100ms
# Micro::Cases.flow([])             7.808k i/100ms
# Micro::Case flow in a class       4.816k i/100ms
# Micro::Case including the class   4.094k i/100ms
# Micro::Case::Result#|             7.656k i/100ms
# Micro::Case::Result#then          7.138k i/100ms

# Calculating -------------------------------------
# Interactor::Organizer             24.290k (±24.0%) i/s -    113.967k in   5.032825s
# Micro::Cases.flow([])             74.790k (±11.1%) i/s -    374.784k in   5.071740s
# Micro::Case flow in a class       47.043k (± 8.0%) i/s -    235.984k in   5.047477s
# Micro::Case including the class   42.030k (± 8.5%) i/s -    208.794k in   5.002138s
# Micro::Case::Result#|             80.936k (±15.9%) i/s -    398.112k in   5.052531s
# Micro::Case::Result#then          71.459k (± 8.8%) i/s -    356.900k in   5.030526s

# Comparison:
# Micro::Case::Result#|:            80936.2 i/s
# Micro::Cases.flow([]):            74790.1 i/s - same-ish: difference falls within error
# Micro::Case::Result#then:         71459.5 i/s - same-ish: difference falls within error
# Micro::Case flow in a class:      47042.6 i/s - 1.72x  (± 0.00) slower
# Micro::Case including the class:  42030.2 i/s - 1.93x  (± 0.00) slower
# Interactor::Organizer:            24290.3 i/s - 3.33x  (± 0.00) slower
```
</details>

<details>
  <summary><strong>Failure results</strong> - Show the full benchmark/ips results.</summary>

```ruby
# Warming up --------------------------------------
# Interactor::Organizer            1.734k i/100ms
# Micro::Cases.flow([])            7.515k i/100ms
# Micro::Case flow in a class      4.636k i/100ms
# Micro::Case including the class  4.114k i/100ms
# Micro::Case::Result#|            7.588k i/100ms
# Micro::Case::Result#then         6.681k i/100ms

# Calculating -------------------------------------
# Interactor::Organizer            24.280k (±24.5%) i/s -    112.710k in   5.013334s
# Micro::Cases.flow([])            74.999k (± 9.8%) i/s -    375.750k in   5.055777s
# Micro::Case flow in a class      46.681k (± 9.3%) i/s -    236.436k in   5.105105s
# Micro::Case including the class  41.921k (± 8.9%) i/s -    209.814k in   5.043622s
# Micro::Case::Result#|            78.280k (±12.6%) i/s -    386.988k in   5.022146s
# Micro::Case::Result#then         68.898k (± 8.8%) i/s -    347.412k in   5.080116s

# Comparison:
# Micro::Case::Result#|:            78280.4 i/s
# Micro::Cases.flow([]):            74999.4 i/s - same-ish: difference falls within error
# Micro::Case::Result#then:         68898.4 i/s - same-ish: difference falls within error
# Micro::Case flow in a class:      46681.0 i/s - 1.68x  (± 0.00) slower
# Micro::Case including the class:  41920.8 i/s - 1.87x  (± 0.00) slower
# Interactor::Organizer:            24280.0 i/s - 3.22x  (± 0.00) slower
```
</details>

https://github.com/serradura/u-case/blob/main/benchmarks/perfomance/flow/

[⬆️ Back to Top](#table-of-contents-)

### Running the benchmarks

#### Performance (Benchmarks IPS)

Clone this repo and access its folder, then run the commands below:

**Use cases**

```sh
ruby benchmarks/perfomance/use_case/failure_results.rb
ruby benchmarks/perfomance/use_case/success_results.rb
```

**Flows**

```sh
ruby benchmarks/perfomance/flow/failure_results.rb
ruby benchmarks/perfomance/flow/success_results.rb
```

#### Memory profiling

**Use cases**

```sh
./benchmarks/memory/use_case/success/with_transitions/analyze.sh
./benchmarks/memory/use_case/success/without_transitions/analyze.sh
```

**Flows**

```sh
./benchmarks/memory/flow/success/with_transitions/analyze.sh
./benchmarks/memory/flow/success/without_transitions/analyze.sh
```

[⬆️ Back to Top](#table-of-contents-)

### Comparisons

Check it out implementations of the same use case with different gems/abstractions.

* [interactor](https://github.com/serradura/u-case/blob/main/comparisons/interactor.rb)
* [u-case](https://github.com/serradura/u-case/blob/main/comparisons/u-case.rb)

[⬆️ Back to Top](#table-of-contents-)

## Examples

### 1️⃣ Users creation

> An example of a flow that defines steps to sanitize, validate, and persist its input data. It has all possible approaches to represent use cases using the `u-case` gem.
>
> Link: https://github.com/serradura/u-case/blob/main/examples/users_creation

### 2️⃣ Rails App (API)

> This project shows different kinds of architecture (one per commit), and in the last one, how to use the `Micro::Case` gem to handle the application business logic.
>
> Link: https://github.com/serradura/from-fat-controllers-to-use-cases

### 3️⃣ CLI calculator

> Rake tasks to demonstrate how to handle user data, and how to use different failure types to control the program flow.
>
> Link: https://github.com/serradura/u-case/tree/main/examples/calculator

### 4️⃣ Rescuing exceptions inside of the use cases

> Link: https://github.com/serradura/u-case/blob/main/examples/rescuing_exceptions.rb

[⬆️ Back to Top](#table-of-contents-)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `./test.sh` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/serradura/u-case. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Micro::Case project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/serradura/u-case/blob/main/CODE_OF_CONDUCT.md).
