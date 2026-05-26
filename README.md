<p align="center">
  <h1 align="center" id="-case"><img src="./assets/ucase_logo_v1.png" alt="μ-case" height="150"></h1>
  <p align="center"><i>Represent use cases in a simple and powerful way: write modular, expressive, sequentially logical code.</i></p>
  <p align="center">
    <a href="https://badge.fury.io/rb/u-case"><img src="https://badge.fury.io/rb/u-case.svg" alt="Gem Version" height="18"></a>
    <a href="https://github.com/serradura/u-case/actions/workflows/ci.yml"><img alt="Build Status" src="https://github.com/serradura/u-case/actions/workflows/ci.yml/badge.svg"></a>
    <br/>
    <a href="https://qlty.sh/gh/serradura/projects/u-case"><img src="https://qlty.sh/gh/serradura/projects/u-case/maintainability.svg" alt="Maintainability" /></a>
    <a href="https://qlty.sh/gh/serradura/projects/u-case"><img src="https://qlty.sh/gh/serradura/projects/u-case/coverage.svg" alt="Code Coverage" /></a>
    <br/>
    <img src="https://img.shields.io/badge/Ruby%20%3E%3D%202.7%2C%20%3C%3D%20Head-ruby.svg?colorA=444&colorB=333" alt="Ruby">
    <img src="https://img.shields.io/badge/Rails%20%3E%3D%206.0%2C%20%3C%3D%20Edge-rails.svg?colorA=444&colorB=333" alt="Rails">
  </p>
  <p align="center">🇧🇷&nbsp;🇵🇹 <a href="https://github.com/serradura/u-case/blob/main/README.pt-BR.md">Leia este README em português</a></p>
</p>

> [!IMPORTANT]
> **No breaking API changes — ever.** From here on, `u-case`'s public API and runtime contracts won't break. The gem's role is to remain a stable, backward-compatible foundation for the projects that already depend on it. Any "next major" rethink of the abstractions belongs in [`solid-process`](https://github.com/solid-process/solid-process) (a redesign that applies what we've learned since `u-case` was created), **not** in a future `u-case` 6.x.
>
> Major version bumps signal only that a Ruby or Rails version was dropped from the supported matrix — per SemVer, a dependency-floor change. Your code keeps working.
>
> See the full statement on [issue #131](https://github.com/serradura/u-case/issues/131#issuecomment-4531231882).

## A 30-second taste <!-- omit in toc -->

```ruby
class Slugify < Micro::Case
  attribute :title, accept: String

  def call!
    slug = title.downcase.strip.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')

    slug.empty? ? Failure(:blank_title) : Success(result: { slug: })
  end
end

Slugify.call(title: 'Hello, World!')
# => #<Micro::Case::Result success? type=:ok data={ slug: "hello-world" }>

Slugify
  .call(title: 42)
  .on_success { |r| puts r[:slug] }
  .on_failure(:invalid_attributes) { |r| warn r[:errors] }
# warn: { "title" => "expected to be a kind of String" }
```

That's the whole shape: `attributes`, a `call!` method, `Success(...)` or `Failure(...)`. Everything else in this README is a way to make that shape easier to **compose**, **validate**, **observe**, and **transact**.

> [!TIP]
> Attributes can nest. `attribute :customer do … end` declares structured input inline, and `accept:` can target another attribute class for auto-coercion. See [Going further with `u-attributes`](#going-further-with-u-attributes) at the end of this README.

## What you get <!-- omit in toc -->

- **Easy** — input → process → output. A use case is a class with `attributes`, a `call!` method, and returns a `Result`.
- **Immutable & callback-free** — no lifecycle callbacks. Data flows forward; nothing mutates in place.
- **Composable three ways** — chain use cases via [`flows`](#flows) or [`Result#then`](#internal-steps--resultthen-chains).
- **Typed results** — every call returns a [`Result`](#working-with-results).
- **Pattern matching** — Ruby `case`/`in` works out of the box. (See [Pattern matching](#pattern-matching)).
- **Result contracts** — declare which types and values a use case can return. (See [Result contracts](#result-contracts)).
- **Inspectable execution** — every flow records each step's input, output. (See [`transitions`](#inspecting-execution-with-resulttransitions)).
- ⚡ **Transactions on demand** — wrap a use case, a [`flow`](#transactions), or an inline `Result#then` chain in an `ActiveRecord` transaction.
- **Exception-safe by opt-in** — [`Micro::Case::Safe`](#safe-mode--capturing-exceptions) turns unhandled exceptions into `:exception` failures.
- **Fast** — Check out the [benchmarks](#performance), with no global state.

> See a real Rails app using this gem: [from-fat-controllers-to-use-cases](https://github.com/serradura/from-fat-controllers-to-use-cases).

## Documentation <!-- omit in toc -->

| Version    | Documentation                                           |
| ---------- | ------------------------------------------------------- |
| unreleased | https://github.com/serradura/u-case/blob/main/README.md |
| 5.7.1      | https://github.com/serradura/u-case/blob/v5.x/README.md |
| 4.5.2      | https://github.com/serradura/u-case/blob/v4.x/README.md |

## Table of Contents <!-- omit in toc -->

- [Compatibility](#compatibility)
- [Dependencies](#dependencies)
- [Installation](#installation)
- [Usage](#usage)
  - [Defining a use case](#defining-a-use-case)
    - [The basics](#the-basics)
    - [Strict mode — required attributes](#strict-mode--required-attributes)
    - [Safe mode — capturing exceptions](#safe-mode--capturing-exceptions)
      - [Safe flows](#safe-flows)
      - [`Result#on_exception`](#resulton_exception)
      - [Opting out of Safe](#opting-out-of-safe)
  - [Working with results](#working-with-results)
    - [The Result API](#the-result-api)
    - [Default and custom result types](#default-and-custom-result-types)
    - [Result contracts](#result-contracts)
    - [Result hooks](#result-hooks)
    - [Pattern matching](#pattern-matching)
    - [Decomposition](#decomposition)
    - [Dynamic continuations with `Result#then`](#dynamic-continuations-with-resultthen)
  - [Validating attributes](#validating-attributes)
    - [`accept:` and `reject:` (default)](#accept-and-reject-default)
    - [ActiveModel integration (opt-in)](#activemodel-integration-opt-in)
      - [Disabling auto-validation for a specific use case](#disabling-auto-validation-for-a-specific-use-case)
      - [`Kind::Validator`](#kindvalidator)
  - [Composing use cases](#composing-use-cases)
    - [Flows](#flows)
      - [Composing flows together](#composing-flows-together)
      - [Data accumulation through a flow](#data-accumulation-through-a-flow)
      - [Inspecting execution with `result.transitions`](#inspecting-execution-with-resulttransitions)
      - [Composing a flow that includes itself](#composing-a-flow-that-includes-itself)
    - [Internal steps — `Result#then` chains](#internal-steps--resultthen-chains)
      - [Accepted link shapes](#accepted-link-shapes)
      - [A minimal example](#a-minimal-example)
      - [`|` pipe alias](#-pipe-alias)
      - [Lambda / `Method` forms](#lambda--method-forms)
      - [`Failure` short-circuits the chain](#failure-short-circuits-the-chain)
      - [Using an internal-step case inside an outer flow](#using-an-internal-step-case-inside-an-outer-flow)
      - [Persistence without a transaction](#persistence-without-a-transaction)
    - [Transactions](#transactions)
      - [Inline `transaction { ... }` inside `call!`](#inline-transaction----inside-call)
      - [`transaction with: …` — declaring the default for a case](#transaction-with---declaring-the-default-for-a-case)
      - [Flow-level transactions](#flow-level-transactions)
      - [Global default — `config.default_transaction_class { … }`](#global-default--configdefault_transaction_class---)
      - [Internal-step flows under transactions](#internal-step-flows-under-transactions)
      - [Behavior notes](#behavior-notes)
- [Configuration](#configuration)
- [Performance](#performance)
  - [Running the benchmarks](#running-the-benchmarks)
  - [Disabling runtime checks](#disabling-runtime-checks)
  - [Comparisons](#comparisons)
- [Examples](#examples)
  - [An end-to-end sign-up flow](#an-end-to-end-sign-up-flow)
  - [More examples](#more-examples)
- [Going further with `u-attributes`](#going-further-with-u-attributes)
  - [Nested attributes (block form)](#nested-attributes-block-form)
  - [Accepting another attribute class](#accepting-another-attribute-class)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)
- [Code of Conduct](#code-of-conduct)

## Compatibility

| u-case     | branch | ruby     | activemodel    | u-attributes  |
| ---------- | ------ | -------- | -------------- | ------------- |
| unreleased | main   | >= 2.7   | >= 6.0         | >= 2.8, < 4.0 |
| 5.7.1      | v5.x   | >= 2.7   | >= 6.0         | >= 2.8, < 4.0 |
| 4.5.2      | v4.x   | >= 2.2.0 | >= 3.2, <= 8.1 | >= 2.7, < 3.0 |

This library is tested (CI matrix) against:

| Ruby / Rails | 6.0 | 6.1 | 7.0 | 7.1 | 7.2 | 8.0 | 8.1 | Edge |
| ------------ | --- | --- | --- | --- | --- | --- | --- | ---- |
| 2.7          | ✅  | ✅  | ✅  | ✅  |     |     |     |      |
| 3.0          | ✅  | ✅  | ✅  | ✅  |     |     |     |      |
| 3.1          |     |     | ✅  | ✅  | ✅  |     |     |      |
| 3.2          |     |     | ✅  | ✅  | ✅  | ✅  |     |      |
| 3.3          |     |     | ✅  | ✅  | ✅  | ✅  | ✅  | ✅   |
| 3.4          |     |     |     |     | ✅  | ✅  | ✅  | ✅   |
| 4.x          |     |     |     |     |     |     | ✅  | ✅   |
| Head         |     |     |     |     |     |     | ✅  | ✅   |

> ActiveModel is an optional dependency — enable [`u-case/with_activemodel_validation`](#activemodel-integration-opt-in) only if you want it.

## Dependencies

1. **[`kind`](https://github.com/serradura/kind)** — a runtime type system for Ruby, used to validate some internal `u-case` inputs. Also exposes the [`Kind::Validator`](https://github.com/serradura/kind#kindvalidator-activemodelvalidations) that ships with [`u-case/with_activemodel_validation`](#activemodel-integration-opt-in). The examples below use `Kind.of?(SomeClass, *values)` as shorthand for runtime type checks — equivalent to `values.all? { |v| v.is_a?(SomeClass) }`.
2. **[`u-attributes`](https://github.com/serradura/u-attributes)** — read-only attribute declarations (getters only). Used for the use case's `attributes`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'u-case', '~> 5.0'
```

Then run `bundle`, or install it yourself with `gem install u-case`.

## Usage

### Defining a use case

#### The basics

```ruby
class ValidateEmail < Micro::Case
  # 1. Declare the input as attributes
  attribute :address

  # 2. Implement call! with the business logic
  def call!
    # 3. Wrap the output with Success(...) or Failure(...)
    if address.is_a?(String) && address.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)
      Success result: { address: address.downcase }
    else
      Failure result: { message: '`address` must be a valid email' }
    end
  end
end

result = ValidateEmail.call(address: 'Ada@Example.com')
result.success? # => true
result.data     # => { address: "ada@example.com" }

bad_result = ValidateEmail.call(address: 'not-an-email')
bad_result.failure? # => true
bad_result.data     # => { message: "`address` must be a valid email" }
```

The object returned by `.call` is a [`Micro::Case::Result`](#working-with-results) — the subject of the next section.

#### Strict mode — required attributes

`Micro::Case::Strict` requires every declared attribute to be passed on `.call`. Missing keywords raise `ArgumentError`:

```ruby
class FormatGreeting < Micro::Case::Strict
  attributes :name, :time_of_day

  def call!
    Success result: { message: "Good #{time_of_day}, #{name}!" }
  end
end

FormatGreeting.call(name: 'Ada')
# => ArgumentError (missing keyword: :time_of_day)
```

Use it when you want missing input to fail loudly instead of letting `time_of_day` arrive as `nil` and produce a silently wrong message.

#### Safe mode — capturing exceptions

`Micro::Case::Safe` is another base class. It auto-intercepts any exception raised inside `call!` and turns it into a `Failure` with `type: :exception`. The exception itself is available under `result[:exception]`:

```ruby
require 'json'
require 'logger'

AppLogger = Logger.new(STDOUT)

class ParseJsonPayload < Micro::Case::Safe
  attribute :payload

  def call!
    return Failure(:blank_payload) if payload.to_s.empty?

    Success result: { data: JSON.parse(payload) }
  end
end

result = ParseJsonPayload.call(payload: 'not-valid-json')
result.type                                 # => :exception
result.data                                 # => { exception: #<JSON::ParserError ...> }
result[:exception].is_a?(JSON::ParserError) # => true

result.on_failure(:exception) do |r|
  AppLogger.error(r[:exception].message)
end
```

To branch on the exception class, use `case`/`when` (or [pattern matching](#pattern-matching)) inside the hook:

```ruby
result.on_failure(:exception) do |data, use_case|
  case (e = data[:exception])
  when JSON::ParserError then AppLogger.error("malformed JSON: #{e.message}")
  else                        AppLogger.debug("#{use_case.class.name} raised #{e.class}")
  end
end
```

You can still `rescue` an exception explicitly inside a Safe use case — see [these test examples](https://github.com/serradura/u-case/blob/main/test/micro/case/safe_test.rb).

##### Safe flows

A safe flow intercepts exceptions in any of its steps:

```ruby
module Users
  Create = Micro::Cases.safe_flow([
    ProcessParams,
    ValidateParams,
    Persist,
    SendToCRM
  ])

  # Or as a class:
  class Create < Micro::Case::Safe
    flow ProcessParams,
         ValidateParams,
         Persist,
         SendToCRM
  end
end
```

##### `Result#on_exception`

Exceptions are easier to follow when they're handled like any other failure. `Result#on_exception` is a hook that fires when `type` is `:exception` — it reads the same as `on_failure(:exception)`, but makes the intent explicit:

```ruby
class ParseJsonPayload < Micro::Case::Safe
  attribute :payload

  def call!
    Success result: { data: JSON.parse(payload) }
  end
end

ParseJsonPayload
  .call(payload: 'not-valid-json')
  .on_success { |r| puts r[:data].inspect }
  .on_exception(Encoding::CompatibilityError) { puts 'Encoding mismatch.' }
  .on_exception(JSON::ParserError) { |_e| puts 'Malformed JSON.' }
  .on_exception { |_e, _use_case|  puts 'Something went wrong.' }
# Malformed JSON.
# Something went wrong.
```

> Both the typed `on_exception(JSON::ParserError)` and the catch-all `on_exception` fire — like all u-case hooks, every match runs in declaration order (see [Result hooks](#result-hooks)).

##### Opting out of Safe

The Safe mechanism is opinionated: any unhandled exception becomes a `:exception` failure. That convenience can fragment a codebase — some exceptions handled by `rescue` inside `call!`, others by `on_exception` later. If you want a single explicit convention (plain `rescue` only), disable Safe entirely:

```ruby
Micro::Case.config do |config|
  config.disable_safe_features = true
end
```

When set to `true`, the following raise `Micro::Case::Error::SafeFeaturesDisabled`:

- subclassing `Micro::Case::Safe`
- calling `Micro::Cases.safe_flow(...)`
- calling `Micro::Case::Result#on_exception`

[⬆️ Back to Top](#table-of-contents-)

### Working with results

A `Micro::Case::Result` carries the use case's output. The methods you'll reach for most:

#### The Result API

- `#success?` / `#failure?` — boolean discriminants.
- `#type` — `Symbol` describing the result (`:ok`, `:error`, `:exception`, or any custom type).
- `#data` — the result data hash. `#value` is a backwards-compatible alias.
- `#[]`, `#values_at`, `#fetch`, `#fetch_values`, `#keys`, `#key?`, `#value?`, `#slice` — `Hash`-like access into `#data`.
- `#use_case` — the use case instance that produced the result (handy for failure diagnostics inside a flow).
- `#on_success` / `#on_failure` / `#on_exception` — hooks for branching on the result.
- `#then` — apply another use case (or lambda / method / symbol) to a successful result; the basis for [internal steps](#internal-steps--resultthen-chains) and [dynamic continuations](#dynamic-continuations-with-resultthen).
- `#transitions` — array of every step that produced this result; see [inspecting execution](#inspecting-execution-with-resulttransitions).

Result objects also support [pattern matching](#pattern-matching) and [array decomposition](#decomposition).

#### Default and custom result types

Every result carries a type. The defaults:

- `:ok` — for `Success(...)`.
- `:error` — for `Failure(...)` whose payload is a `Hash`.
- `:exception` — for `Failure(result: some_exception)` (an `Exception` instance).

```ruby
class FetchUser < Micro::Case
  attribute :id

  def call!
    return Failure(result: { errors: { id: 'must be an Integer' } }) unless id.is_a?(Integer)

    Success result: { user: User.find(id) }
  rescue => exception
    Failure result: exception
  end
end

FetchUser.call(id: 1).type        # => :ok
FetchUser.call(id: 'x').type      # => :error
FetchUser.call(id: 999_999).type  # => :exception   (ActiveRecord::RecordNotFound)
```

Pass a symbol as the first argument of `Success(...)` / `Failure(...)` to give the result a custom type:

```ruby
class MergeTags < Micro::Case
  attributes :primary, :secondary

  def call!
    if primary.is_a?(Array) && secondary.is_a?(Array)
      Success result: { tags: (primary + secondary).uniq }
    else
      Failure :invalid_input, result: {
        attributes: attributes.reject { |_, v| v.is_a?(Array) }
      }
    end
  end
end

MergeTags.call(primary: %w[ruby], secondary: 'rails').type # => :invalid_input
```

Passing only the symbol (no `result:`) is allowed — the data becomes `{ <symbol> => true }`. This shape is useful as a quick discriminant inside a flow:

```ruby
def call!
  return Failure(:invalid_input) unless primary.is_a?(Array) && secondary.is_a?(Array)

  Success result: { tags: (primary + secondary).uniq }
end

# result.data => { invalid_input: true }
```

#### Result contracts

Use the `results do |on| ... end` macro to declare which result types your use case can produce and which keys each one requires. Calls that use an undeclared type raise `Micro::Case::Error::UnexpectedResultType`; calls that omit a declared required key raise `Micro::Case::Error::MissingResultKeys`.

```ruby
class PublishPost < Micro::Case
  attribute :post

  results do |on|
    on.failure(:already_published)
    on.failure(:missing_content)

    on.success(result: [:post])
  end

  def call!
    return Failure(:already_published) if post.published?
    return Failure(:missing_content)   if post.body.to_s.strip.empty?

    post.update!(status: :published, published_at: Time.current)
    Success result: { post: post }
  end
end

PublishPost.call(post: ready_post).data        # => { post: #<Post ...> }
PublishPost.call(post: empty_post).type        # => :missing_content
PublishPost.call(post: already_live_post).type # => :already_published
```

A type passed without `result:` declares it with no required keys (any payload — including the implicit `{ type => true }` from `Failure(:my_type)` — is accepted). With `result: [:key1, :key2]`, those keys must be present in the result hash; extra keys are fine.

```ruby
class CreateComment < Micro::Case
  results do |on|
    on.success(result: [:comment])
    on.failure(:spam)
  end

  def call!
    Success(:moderated, result: { comment: ... }) # raises Micro::Case::Error::UnexpectedResultType
    # Success(result: { body: '...' })            # raises Micro::Case::Error::MissingResultKeys
    # Failure(:rate_limited)                      # raises Micro::Case::Error::UnexpectedResultType
  end
end
```

Notes:

- Use cases without a `results` block keep their previous unrestricted behavior — the contract is opt-in.
- Subclasses inherit the parent's contract.
- The auto-failure produced by [`accept:` / `reject:`](#accept-and-reject-default) attribute validation bypasses the contract — combining `results` with attribute validation does **not** require declaring `:invalid_attributes`.
- Rescued exceptions in [`Micro::Case::Safe`](#safe-mode--capturing-exceptions) (which produce `Failure(result: exception)`) bypass the contract too.
- Contracts are independent of [hooks](#result-hooks) and [pattern matching](#pattern-matching): the contract fires at `Success(...)` / `Failure(...)` call time, inside `call!`. Once a `Result` exists, callers consume it normally — there is no caller-side enforcement.

#### Result hooks

`on_success` and `on_failure` branch on the result type. Pass a symbol to match a specific type, or no argument to match anything:

```ruby
class ChangePassword < Micro::Case
  attributes :user, :new_password

  def call!
    return Failure(:weak,   result: { msg: 'password too short' }) unless new_password.is_a?(String) && new_password.length >= 8
    return Failure(:reused, result: { msg: 'password recently used' }) if user.recently_used?(new_password)

    user.update_password!(new_password)
    Success result: { user: user }
  end
end

ChangePassword
  .call(user: ada, new_password: 'long-enough-1')
  .on_success { |r| audit "password updated for #{r[:user].id}" }
  .on_failure(:weak)   { |r| raise ArgumentError, r[:msg] }
  .on_failure(:reused) { |r| raise ArgumentError, r[:msg] }

ChangePassword
  .call(user: ada, new_password: 'short')
  .on_failure { |_r, use_case| audit "#{use_case.class.name} failed" }   # 1. ChangePassword failed
  .on_failure(:weak)   { |r| raise ArgumentError, r[:msg] }              # 2. ArgumentError
```

> The use case responsible for the result is always available as the hook's second block argument.

Without an explicit type, the block receives the whole result, so you can branch with a `case` statement:

```ruby
ChangePassword
  .call(user: ada, new_password: 'short')
  .on_failure do |result, use_case|
    case result.type
    when :weak   then raise ArgumentError, 'password too short'
    when :reused then raise ArgumentError, 'password recently used'
    else raise NotImplementedError
    end
  end
```

If the same hook is declared multiple times, every match fires:

```ruby
calls = 0
result = ChangePassword.call(user: ada, new_password: 'long-enough-1')

result
  .on_success     { |_r| calls += 1 }
  .on_success     { |_r| calls += 1 }
  .on_success(:ok) { |_r| calls += 1 }
  .on_success(:ok) { |_r| calls += 1 }

calls # => 4
```

#### Pattern matching

`Micro::Case::Result` implements [`deconstruct`](https://docs.ruby-lang.org/en/3.4/syntax/pattern_matching_rdoc.html) and [`deconstruct_keys`](https://docs.ruby-lang.org/en/3.4/syntax/pattern_matching_rdoc.html), so Ruby `case`/`in` works out of the box (Ruby ≥ 2.7):

```ruby
case result
in { success: _, data: { number: Numeric => number } }
  puts "got #{number}"
in { failure: :invalid_attributes, data: { invalid_attributes: errors } }
  warn "bad input: #{errors.keys.join(", ")}"
in { failure: :exception, data: { exception: } }
  warn "boom: #{exception.message}"
end
```

The hash patterns expose these keys:

| Key            | Present on   | Value                                                                        |
| -------------- | ------------ | ---------------------------------------------------------------------------- |
| `success:`     | success only | the result `type` (e.g. `:ok`)                                               |
| `failure:`     | failure only | the result `type` (e.g. `:invalid_attributes`)                               |
| `type:`        | always       | the result `type`                                                            |
| `data:`        | always       | the result `data` hash                                                       |
| `result:`      | always       | alias of `data:` (matches the `Success(result: …)` keyword at the call site) |
| `use_case:`    | always       | the use case instance that produced the result                               |
| `transitions:` | always       | the result `transitions` array                                               |

`Result#deconstruct` returns a three-element array `[status, type, data]` where `status` is `:success` or `:failure`, so array patterns can use the status as a discriminant — mirroring how libraries with separate `Success` / `Failure` classes are pattern-matched, even though `Micro::Case::Result` is a single class:

```ruby
case result
in [:success, :ok, { number: Integer => n }]
  n
in [:failure, :invalid_attributes, { invalid_attributes: errors }]
  # ...
in [:failure, :exception, { exception: }]
  # ...
end
```

> `Result#to_ary` is unchanged and still returns `[data, type]` (used by multi-assignment, e.g. `data, type = result`). Ruby's pattern matching uses `#deconstruct`, so the two intentionally return different shapes.

#### Decomposition

Inside a hook without a type, the result can also be array-decomposed into `[data, type]`:

```ruby
ChangePassword
  .call(user: ada, new_password: 'short')
  .on_failure do |(data, type), use_case|
    case type
    when :weak   then raise ArgumentError, data[:msg]
    when :reused then raise ArgumentError, data[:msg]
    else raise NotImplementedError
    end
  end
```

#### Dynamic continuations with `Result#then`

`Result#then` applies another use case (or callable) to a successful result — `Failure` short-circuits. Use it to build dynamic continuations from a result that already exists:

```ruby
class FindActiveUser < Micro::Case
  attribute :email

  def call!
    user = User.active.find_by(email: email)

    return Success result: { user: user } if user

    Failure result: { email: email }
  end
end

class GenerateInviteToken < Micro::Case
  attribute :user

  def call!
    Success result: { user: user, token: SecureRandom.hex(16) }
  end
end

FindActiveUser.call(email: 'unknown@example.com').then(GenerateInviteToken).failure? # => true
FindActiveUser.call(email: 'ada@example.com').then(GenerateInviteToken).data
# => { user: #<User ...>, token: "9f2b…" }
```

Passing a block yields `self` (a `Micro::Case::Result`) and returns the block's value — handy for unwrapping into a non-result type:

```ruby
class FindUser < Micro::Case
  attribute :email

  def call!
    user = User.find_by(email: email)

    user ? Success(result: { user: user }) : Failure(:not_found)
  end
end

FindUser.call(email: 'ada@example.com').then  { |r| r.success? ? r[:user].id : nil } # => 42
FindUser.call(email: 'unknown@example.com').then { |r| r.success? ? r[:user].id : nil } # => nil
```

Pass an extra `Hash` to inject attributes into the next use case:

```ruby
Todo::FindAllForUser
  .call(user: current_user, params: params)
  .then(Paginate)
  .then(Serialize::PaginatedRelationAsJson, serializer: Todo::Serializer)
  .on_success { |r| render_json(200, data: r[:todos]) }
```

> `Result#then` also accepts a `Symbol`, a `Method` object, or a `Lambda` — see [Internal steps](#internal-steps--resultthen-chains).

[⬆️ Back to Top](#table-of-contents-)

### Validating attributes

#### `accept:` and `reject:` (default)

Since 5.2.0, every use case includes [`u-attributes`' `accept` extension](https://github.com/serradura/u-attributes). Declare a type expectation (or any predicate) on the attribute, and the use case fails automatically with `type: :invalid_attributes` when an attribute is rejected — no need to validate inside `call!`:

```ruby
class CreateUser < Micro::Case
  attribute :name,  accept: String
  attribute :email, accept: ->(v) { v.is_a?(String) && v.include?('@') }
  attribute :age,   accept: Integer, allow_nil: true

  def call!
    Success result: { user: User.create!(attributes) }
  end
end

CreateUser.call(name: 'Bob', email: 'bob@example.com')
# => #<Success type=:ok ...>

CreateUser.call(name: 42, email: 'not-an-email')
# => #<Failure type=:invalid_attributes data={
#       errors: {
#         "name"  => "expected to be a kind of String",
#         "email" => "is invalid"
#       }
#     }>
```

The failure type follows the same setting used by the ActiveModel integration — see `set_activemodel_validation_errors_failure` in [Configuration](#configuration).

#### ActiveModel integration (opt-in)

You can layer Rails-style `validates` on top of `accept:` / `reject:` for richer rules (`presence`, `numericality`, `format`, custom validators…). Requires [`activemodel >= 6.0`](https://rubygems.org/gems/activemodel) in your application.

The simplest form — `validates` is available on every use case, you fail manually:

```ruby
class CreatePost < Micro::Case
  attributes :title, :body

  validates :title, :body, presence: true
  validates :title, length: { maximum: 120 }

  def call!
    return Failure :invalid_attributes, result: { errors: self.errors } if invalid?

    Success result: { post: Post.create!(title: title, body: body) }
  end
end
```

To make use cases **auto-fail** on `invalid?`, require the auto-validation entry point:

```ruby
# Gemfile
gem 'u-case', require: 'u-case/with_activemodel_validation'
```

…or enable it via [Configuration](#configuration). The example then collapses:

```ruby
require 'u-case/with_activemodel_validation'

class CreatePost < Micro::Case
  attributes :title, :body

  validates :title, :body, presence: true
  validates :title, length: { maximum: 120 }

  def call!
    Success result: { post: Post.create!(title: title, body: body) }
  end
end
```

When both `accept:` and ActiveModel validation are present, the execution order is:

1. `u-attributes` resolves each attribute's default.
2. `u-attributes` runs the `accept:` / `reject:` checks.
3. `u-case` runs the ActiveModel validations **only if** every attribute was accepted.

> Auto-validation is also inherited by `Micro::Case::Strict` and `Micro::Case::Safe`.

##### Disabling auto-validation for a specific use case

Use the `disable_auto_validation` macro:

```ruby
require 'u-case/with_activemodel_validation'

class CountPosts < Micro::Case
  disable_auto_validation

  attribute :user
  validates :user, presence: true

  def call!
    Success result: { count: user.posts.count }
  end
end

CountPosts.call(user: nil)
# => NoMethodError (undefined method `posts' for nil:NilClass)
```

##### `Kind::Validator`

The [`kind` gem](https://github.com/serradura/kind) ships a [`Kind::Validator`](https://github.com/serradura/kind#kindvalidator-activemodelvalidations) for ActiveModel that validates types via its runtime type system. Requiring `'u-case/with_activemodel_validation'` also loads `Kind::Validator`:

```ruby
class Todo::List::AddItem < Micro::Case
  attributes :user, :params

  validates :user,   kind: User
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

### Composing use cases

A composition chains use cases so that each step's `Success` data feeds the next step's input. There are two ways to compose: [Flows](#flows) — covering both `Micro::Cases.flow(...)` and the class-level `flow ...` macro — and [Internal steps](#internal-steps--resultthen-chains) (the `Result#then` / `|` chain inside a single `call!`). Either form can be wrapped in a [Transaction](#transactions).

#### Flows

A `Micro::Cases::Flow` is a stand-alone composition. Build one with `Micro::Cases.flow([...])` or the class-level `flow ...` macro:

```ruby
module Steps
  class ParseTags < Micro::Case
    attribute :tags

    def call!
      if tags.is_a?(String)
        Success result: { tags: tags.split(',').map(&:strip) }
      else
        Failure result: { message: 'tags must be a comma-separated String' }
      end
    end
  end

  class Downcase < Micro::Case::Strict
    attribute :tags
    def call!; Success result: { tags: tags.map(&:downcase) }; end
  end

  class StripHashPrefix < Micro::Case::Strict
    attribute :tags
    def call!; Success result: { tags: tags.map { |t| t.sub(/\A#/, '') } }; end
  end

  class RemoveDuplicates < Micro::Case::Strict
    attribute :tags
    def call!; Success result: { tags: tags.uniq }; end
  end
end

# Using the module-level constructor:
DowncaseTags = Micro::Cases.flow([
  Steps::ParseTags,
  Steps::Downcase
])

DowncaseTags.call(tags: 'Ruby, Rails, RUBY').data
# => { tags: ["ruby", "rails", "ruby"] }

# Using a class:
class NormalizeTags < Micro::Case
  flow Steps::ParseTags,
       Steps::Downcase,
       Steps::StripHashPrefix,
       Steps::RemoveDuplicates
end

NormalizeTags
  .call(tags: 42)
  .on_failure { |r| puts r[:message] }
# => "tags must be a comma-separated String"
```

When a flow fails, `Result#use_case` points to the step responsible:

```ruby
result = NormalizeTags.call(tags: 42)
result.failure?                          # => true
result.use_case.is_a?(Steps::ParseTags)  # => true
```

##### Composing flows together

Flows can be steps inside other flows. Mix any of the three composition styles:

```ruby
DowncaseTags           = Micro::Cases.flow([Steps::ParseTags, Steps::Downcase])
DedupedTags            = Micro::Cases.flow([Steps::ParseTags, Steps::RemoveDuplicates])
DowncaseAndDedupedTags = Micro::Cases.flow([DowncaseTags, Steps::RemoveDuplicates])
StrippedAndDeduped     = Micro::Cases.flow([Steps::ParseTags, Steps::StripHashPrefix, Steps::RemoveDuplicates])

DowncaseAndDedupedTags
  .call(tags: 'Ruby, Rails, RUBY')
  .on_success { |r| p r[:tags] } # => ["ruby", "rails"]
```

> See [`test/micro/cases/flow/blend_test.rb`](https://github.com/serradura/u-case/blob/main/test/micro/cases/flow/blend_test.rb) for every blending combination.

##### Data accumulation through a flow

Each step's `Success` output is merged into a running attributes hash that becomes the next step's input. Steps don't have to thread inputs manually — they declare what they need:

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

  class ValidatePassword < Micro::Case::Strict
    attributes :user, :password

    def call!
      return Failure(:user_must_be_persisted) if user.new_record?
      return Failure(:wrong_password)         if user.wrong_password?(password)

      Success result: attributes(:user)
    end
  end

  Authenticate = Micro::Cases.flow([FindByEmail, ValidatePassword])
end

Users::Authenticate
  .call(email: 'somebody@test.com', password: 'password')
  .on_success { |r| sign_in(r[:user]) }
  .on_failure(:wrong_password)  { render status: 401 }
  .on_failure(:user_not_found)  { render status: 404 }
```

`ValidatePassword` declares `:user` as one of its attributes but isn't passed it explicitly — it inherits it from `FindByEmail`'s success result. That's the accumulation contract: output → input.

##### Inspecting execution with `result.transitions`

Every use case (and every internal step) contributes one entry to `result.transitions`. Use it to debug, trace, or test a flow's execution:

```ruby
user_authenticated = Users::Authenticate.call(email: 'rodrigo@test.com', password: '...')

user_authenticated.transitions
# => [
#   {
#     use_case: {
#       class:      Users::FindByEmail,
#       attributes: { email: 'rodrigo@test.com' }
#     },
#     success: { type: :ok, result: { user: #<User ...> } },
#     accessible_attributes: [ :email, :password ]
#   },
#   {
#     use_case: {
#       class:      Users::ValidatePassword,
#       attributes: { user: #<User ...>, password: '...' }
#     },
#     success: { type: :ok, result: { user: #<User ...> } },
#     accessible_attributes: [ :email, :password, :user ]
#   }
# ]
```

Schema:

```ruby
[
  {
    use_case: {
      class:      <Micro::Case>,        # the use case executed
      attributes: <Hash>                # input
    },
    [success:, failure:] => {           # output (one of the two)
      type:   <Symbol>,                 # :ok / :error / :exception / custom
      result: <Hash>                    # data
    },
    accessible_attributes: <Array>      # attributes accessible at this step
                                        # (grows with each success)
  }
]
```

`accessible_attributes` grows as each step's `Success` is merged into the running data. [`Result#then`](#dynamic-continuations-with-resultthen) also contributes a transition.

To disable transitions globally (saves a hash per step), see [Configuration](#configuration).

##### Composing a flow that includes itself

A class can use itself as a step inside its own `flow` declaration via `self.call!`:

```ruby
class ParseTagsString < Micro::Case
  attribute :input
  def call!; Success result: { tags: input.split(',').map(&:strip) }; end
end

class JoinTagsArray < Micro::Case
  attribute :tags
  def call!; Success result: { input: tags.join(', ') }; end
end

class CleanTags < Micro::Case
  flow ParseTagsString,
       self.call!,
       JoinTagsArray

  attribute :tags

  def call!
    Success result: { tags: tags.map(&:downcase).uniq }
  end
end

CleanTags.call(input: 'Ruby, RUBY, Rails').data[:input] # => "ruby, rails"
```

Works with `Micro::Case::Safe` too — see [`test/micro/case/safe/with_inner_flow_test.rb`](https://github.com/serradura/u-case/blob/main/test/micro/case/safe/with_inner_flow_test.rb).

#### Internal steps — `Result#then` chains

`Result#then` (and its `|` pipe alias) is u-case's **third way of composing a flow** — alongside `Micro::Cases.flow(...)` and the class-level `flow ...` macro. Instead of wiring sibling use cases together, you keep the chain _inside_ a single use case's `call!`. Each link is a method, lambda, or another use case class; each link returns a `Micro::Case::Result`; each link's `Success` data becomes the next link's keyword arguments; each link contributes a row to `result.transitions`.

##### Accepted link shapes

| Argument shape           | Example                                          |
| ------------------------ | ------------------------------------------------ |
| `Symbol` (method name)   | `result.then(:strip_title)`                      |
| Bound `Method` object    | `result.then(method(:strip_title))`              |
| `Lambda` / `Proc`        | `result.then(-> data { strip_title(**data) })`   |
| Use case class           | `result.then(CapitalizeTitle)`                   |
| `Symbol` + Hash defaults | `result.then(:add, number: 3)`                   |
| Block                    | `result.then { \|r\| r.success? ? r[:sum] : 0 }` |

The connecting method **must** return a `Micro::Case::Result`. Anything else raises `Micro::Case::Error::UnexpectedResult` (e.g. a method returning a plain `Hash` is rejected with `MyCase#method(:foo) must return an instance of Micro::Case::Result`).

##### A minimal example

```ruby
class CapitalizeTitle < Micro::Case
  attribute :title

  def call!
    Success :capitalized, result: { title: title.split.map(&:capitalize).join(' ') }
  end
end

class CreateBlogPost < Micro::Case
  attributes :raw_title, :body

  def call!
    validate_input
      .then(:strip_title)
      .then(:slugify, separator: '-')
      .then(CapitalizeTitle)
  end

  private

  def validate_input
    Kind.of?(String, raw_title, body) ? Success(:valid) : Failure()
  end

  def strip_title
    Success :stripped, result: { title: raw_title.strip }
  end

  def slugify(title:, separator:, **)
    slug = title.downcase.gsub(/[^a-z0-9]+/, separator)
    Success :slugified, result: { title: title, slug: slug }
  end
end

CreateBlogPost.call(raw_title: '  hello world  ', body: 'lorem ipsum').data
# => { title: "Hello World" }
```

Symbol-, method-, and lambda-based links all run **as the host use case**, so they report `class: CreateBlogPost` in `result.transitions`. Only the `CapitalizeTitle` link (another use case class) contributes a transition with a different `use_case.class`. `accessible_attributes` grows as each link's `Success` output merges into the running data — by the time `CapitalizeTitle` runs, `slug` is also reachable upstream.

##### `|` pipe alias

`|` is sugar for `.then(...)`. The previous example reads:

```ruby
def call!
  validate_input | :strip_title | :slugify | CapitalizeTitle
end
```

Both forms produce identical `result.data` and `result.transitions`.

> **Elixir-style chains with `it` (Ruby ≥ 3.4):** Ruby 3.4 exposes `it` as the implicit first parameter of a block/lambda body, so a chain can read almost exactly like Elixir's `|>`. Each lambda receives the accumulated data hash as `it` and must still terminate in a `Success(...)` / `Failure(...)`:
>
> ```ruby
> def call!
>   validate_something \
>     | -> { do_something_with(**it) } \
>     | -> { and_another_thing_with(**it) }
> end
> ```
>
> On Ruby 2.7 – 3.3 (where `it` is just an undefined identifier), use the explicit form `->(data) { do_something_with(**data) }`.

##### Lambda / `Method` forms

Lambdas (and bound `Method` objects) receive the accumulated data **positionally** as a single Hash:

```ruby
def call!
  validate_input
    .then(method(:strip_title))
    .then(->(data) { slugify(**data, separator: '-') })
    .then(CapitalizeTitle)
end
```

##### `Failure` short-circuits the chain

Returning `Failure(...)` from any link halts the rest of the chain immediately — exactly like a step in a top-level flow returning a failure. The remaining `.then(...)` / `|` links are not invoked; the final `result` is the failure.

##### Using an internal-step case inside an outer flow

A use case that composes internally is just a use case, so it drops into any flow:

```ruby
PublishWorkflow = Micro::Cases.flow([
  AuthorizePublisher,
  CreateBlogPost,     # ← uses .then(:method) internally
  EnqueueIndexingJob
])
```

The host's internal transitions are interleaved with the outer flow's leaf transitions in execution order. If `CreateBlogPost` produces 4 internal transitions and the outer flow has 2 other leaf steps, the final `result.transitions` has 6 entries.

##### Persistence without a transaction

By default — when neither the host class nor the outer flow uses `transaction: true` — internal steps behave like any other code in `call!`: side-effects from earlier links **persist** even if a later link returns `Failure`. The chain stops, but anything already written stays written:

```ruby
class CreateUserWithProfileInline < Micro::Case
  attributes :name, :info

  def call!
    create_user.then(:create_profile)
  end

  private

  def create_user
    user = User.create(name: name)
    Success result: { user: user }
  end

  def create_profile(user:, **)
    profile = UserProfile.create(user_id: user.id, info: info)
    return Failure(:invalid_profile) if profile.errors.any?

    Success result: { user: user, profile: profile }
  end
end

CreateUserWithProfileInline.call(name: 'Rodrigo', info: '')
# create_user already INSERTed the user row; create_profile failed.
# user is persisted; profile is not. No automatic rollback.
```

To roll the partial writes back, wrap the chain in a [transaction](#transactions).

#### Transactions

u-case ships two complementary helpers for wrapping work in an `ActiveRecord::Base.transaction`. Both are opt-in — `active_record` is **not** required by the gem, so you load ActiveRecord yourself (Rails apps already do).

##### Inline `transaction { ... }` inside `call!`

`Micro::Case#transaction` (and `Micro::Case::Safe#transaction`) is a private instance helper that wraps a block in a database transaction and issues `ActiveRecord::Rollback` whenever the block's result is a `Failure`. The original result is returned either way, so you can keep chaining with `Result#then`:

```ruby
class CreateUserWithAProfile < Micro::Case
  def call!
    transaction {
      call(CreateUser).then(CreateUserProfile)
    }
  end
end
```

If the block returns a failure (or raises), every row written inside the block is rolled back. The helper accepts `with:` to pick the ActiveRecord class on which `.transaction` is opened — useful for multi-database Rails apps (`ApplicationRecord`, `AnalyticsRecord`, `BillingRecord`, …):

```ruby
class CreateAuditEntry < Micro::Case
  def call!
    transaction(with: AnalyticsRecord) {
      call(WriteAuditLog).then(BumpCounter)
    }
  end
end
```

When `with:` is omitted, the helper falls back to the class macro (`transaction with: …`) and then to the global default callback.

> Any class passed via `with:` (inline helper, class macro, or flow kwarg) **must be a subclass of `ActiveRecord::Base`**. Non-AR classes are rejected with `ArgumentError`.
>
> **Backward compatibility:** the pre-5.6.0 positional form `transaction(:activerecord) { ... }` still works as an alias for `transaction { ... }`; any other positional value raises `ArgumentError`.

##### `transaction with: …` — declaring the default for a case

A class macro lets a case declare which ActiveRecord class should own its transactions, so neither the inline helper nor any wrapping flow needs to spell it out. The declaration is inherited:

```ruby
class ApplicationUseCase < Micro::Case
  transaction with: ApplicationRecord
end

class CreateUserWithAProfile < ApplicationUseCase
  flow(transaction: true, steps: [CreateUser, CreateUserProfile])
  # transaction: true resolves to ApplicationRecord (inherited).
end

class BillingCase < ApplicationUseCase
  transaction with: BillingRecord
  # overrides the inherited declaration for this branch of the tree
end
```

##### Flow-level transactions

Pass `transaction:` together with `steps:` to wrap an entire flow in a single transaction. If any step returns a failure (or raises, in a `safe_flow`), every database write performed during the flow is rolled back. Three forms:

```ruby
# Use the class-level macro (if the host case declared one) or the global default.
Micro::Cases.flow(transaction: true, steps: [CreateUser, CreateUserProfile])

# Pick an explicit ActiveRecord class for this flow only — same `with:` vocabulary.
Micro::Cases.flow(transaction: { with: AnalyticsRecord }, steps: [
  WriteAuditLog,
  BumpCounter
])

# safe_flow rolls back on failures AND on unexpected exceptions.
Micro::Cases.safe_flow(transaction: { with: ApplicationRecord }, steps: [
  CreateUser,
  CreateUserProfile
])

# Class-level form
class CreateUserWithAProfile < Micro::Case
  flow(transaction: true, steps: [CreateUser, CreateUserProfile])
end
```

To nest a transactional flow inside another flow, wrap it in a use case class — `Micro::Cases.flow([...])` flattens `Flow` instances passed as steps, but does **not** flatten classes:

```ruby
class CreateUserAndProfile < Micro::Case
  flow(transaction: true, steps: [CreateUser, CreateUserProfile])
end

SignUpFlow = Micro::Cases.flow([
  NormalizeParams,
  ValidatePassword,
  CreateUserAndProfile,
  EnqueueIndexingJob
])
```

If `transaction: true` is used while `ActiveRecord::Base` is not loaded, the flow raises `Micro::Cases::Error::TransactionAdapterMissing` on the first call so the misconfiguration surfaces immediately. Passing `transaction: { with: SomeClass }` skips this check — `SomeClass` is trusted to respond to `.transaction`.

##### Global default — `config.default_transaction_class { … }`

For Rails apps that use a single abstract record (`ApplicationRecord`), configure it once in an initializer instead of declaring it on every case or flow:

```ruby
# config/initializers/u_case.rb
Micro::Case.config do |config|
  config.default_transaction_class { ApplicationRecord }
end
```

The callback (block or lambda) is invoked **every time** a transaction opens — no memoization — so the return value can depend on runtime state (per-tenant routing, etc.). The default is `-> { ::ActiveRecord::Base }`.

Resolution order, when a transaction opens:

1. **Call-site override** — `transaction: { with: X }` on a flow kwarg, or `transaction(with: X) { ... }` on the inline helper.
2. **Host case's `transaction with: X` macro** (walks ancestors).
3. **`Micro::Case.config.default_transaction_class.call`** — the global callback (defaults to `ActiveRecord::Base`).

A non-callable assignment to `default_transaction_class=` raises `ArgumentError` at config time so typos like `config.default_transaction_class = 'ApplicationRecord'` fail loudly instead of crashing the first transaction.

##### Internal-step flows under transactions

[Internal steps](#internal-steps--resultthen-chains) — the `Result#then(:symbol)` / `|` form built inline inside a single `call!` — are an _internal_ flow. By default they have **no transactional rollback**: side-effects from earlier `.then(:method)` links persist even when a later link returns `Failure`.

Two natural ways to give them rollback:

**1. Wrap the host case in a `transaction: true` flow.** Recommended once the host case sits inside a larger pipeline. The transaction spans the whole flow call, so a `Failure` _anywhere_ — including from any internal `.then(:method)` link — rolls back every database write:

```ruby
class CreateUserWithProfileInline < Micro::Case
  attributes :name, :info

  def call!
    create_user.then(:create_profile)
  end

  private

  def create_user
    user = User.create(name: name)
    Success result: { user: user }
  end

  def create_profile(user:, **)
    profile = UserProfile.create(user_id: user.id, info: info)
    return Failure(:invalid_profile) if profile.errors.any?

    Success result: { user: user, profile: profile }
  end
end

SignUp = Micro::Cases.flow(transaction: true, steps: [
  NormalizeParams,
  CreateUserWithProfileInline,   # ← internal failure now rolls back
  EnqueueIndexingJob
])
```

If `create_profile` returns `Failure(:invalid_profile)`, the `User` row inserted earlier is rolled back as part of the same `ActiveRecord::Base.transaction`. The result still surfaces the failure type and the partial transitions, but no row is left behind.

**2. Use the inline `transaction { ... }` helper** to scope the rollback to a single `call!` without involving an outer flow:

```ruby
class CreateUserWithProfileInline < Micro::Case
  def call!
    transaction {
      create_user.then(:create_profile)
    }
  end
end
```

The two approaches compose. If `CreateUserWithProfileInline` (using inline `transaction { ... }`) sits inside an outer `transaction: true` flow, ActiveRecord joins the inner transaction into the outer one by default — an outer failure rolls back the inner's writes too.

##### Behavior notes

- **Result is unaffected.** `transaction: true` only affects database side-effects. `result.data`, `result.type`, `result.transitions`, and `result.accessible_attributes` are identical to those of an equivalent non-transactional flow.
- **`Flow` instances get flattened.** `Micro::Cases.flow([inner_flow, Other])` flattens `inner_flow` into its leaf steps — a transactional `Flow` instance passed this way **loses its transaction**. Wrap reusable transactional flows in a use case class to preserve their transaction when nested.
- **Nested transactions join the outer one.** ActiveRecord joins them by default (no `requires_new: true`). A failure anywhere in the chain rolls back **everything** written inside the outermost transaction.
- **A non-transactional outer commits the inner.** If the outer flow is not transactional and the inner transactional flow succeeds, the inner's writes commit at the end of the inner step. A failure in a later (non-transactional) step **does not** undo those writes.
- **Plain `Micro::Cases.flow(transaction: true, ...)` re-raises exceptions.** The transaction still rolls back, but the caller has to rescue. Use `Micro::Cases.safe_flow(transaction: true, ...)` (or the class-level form with `Micro::Case::Safe`) to capture the exception as a `:exception` failure result.

[⬆️ Back to Top](#table-of-contents-)

## Configuration

`Micro::Case.config` exposes the gem's toggles. Set them once — typically in a Rails initializer:

```ruby
Micro::Case.config do |config|
  # Auto-fail use cases on ActiveModel validation errors.
  config.enable_activemodel_validation = false

  # Type symbol used by the auto-failure produced when ActiveModel validation
  # rejects an attribute (shared with the accept:/reject: rejection failure).
  # Default is :invalid_attributes.
  config.set_activemodel_validation_errors_failure = :invalid_attributes

  # Record Micro::Case::Result#transitions on every flow step.
  # Set to false to save the per-step hash allocation in hot paths.
  config.enable_transitions = true

  # Forbid the Safe APIs to enforce a single exception-handling convention
  # (plain `rescue` inside use cases). When true, the following raise
  # Micro::Case::Error::SafeFeaturesDisabled:
  #   - subclassing Micro::Case::Safe
  #   - calling Micro::Cases.safe_flow(...)
  #   - calling Micro::Case::Result#on_exception
  config.disable_safe_features = false

  # Skip the gem's internal argument/contract checks for a small perf win in
  # production once your test suite has exercised the code paths. Misuse will
  # then surface as downstream errors instead of the gem's curated ones.
  config.disable_runtime_checks = false

  # The ActiveRecord class used by `transaction: true`. Pass a block (or lambda).
  # The default is `-> { ::ActiveRecord::Base }`. Override to use a per-app
  # abstract record like ApplicationRecord.
  config.default_transaction_class { ApplicationRecord }
end
```

All internal checks live in `Micro::Case::Check::Enabled` (the default). Toggling `disable_runtime_checks = true` swaps `Micro::Case.check` to `Micro::Case::Check::Disabled`, whose methods are no-ops — the validations themselves stop running on each call.

[⬆️ Back to Top](#table-of-contents-)

## Performance

In benchmarks against comparable abstractions, `Micro::Case` is the fastest after `Dry::Monads`:

| Gem / Abstraction      | Success (i/s) | Failure (i/s) |
| ---------------------- | ------------: | ------------: |
| Dry::Monads            |     315,635.1 |     135,386.9 |
| **Micro::Case**        |      75,837.7 |      73,489.3 |
| Interactor             |      59,745.5 |      27,037.0 |
| Trailblazer::Operation |      28,423.9 |      29,016.4 |
| Dry::Transaction       |      10,130.9 |       8,988.6 |

For flows, the `|` pipe alias is the fastest composition style:

| Composition style                |      Success |      Failure |
| -------------------------------- | -----------: | -----------: |
| `Result#\|` (pipe)               |     80,936.2 |     78,280.4 |
| `Micro::Cases.flow(...)`         |     same-ish |     same-ish |
| `Result#then`                    |     same-ish |     same-ish |
| Class with inner `flow`          | 1.72× slower | 1.68× slower |
| Class including itself as a step | 1.93× slower | 1.87× slower |
| `Interactor::Organizer`          | 3.33× slower | 3.22× slower |

> `Dry::Monads`, `Dry::Transaction`, and `Trailblazer::Operation` don't ship a flow-equivalent feature and are excluded from the flow table.

### Running the benchmarks

```sh
# Use cases
ruby benchmarks/perfomance/use_case/success_results.rb
ruby benchmarks/perfomance/use_case/failure_results.rb

# Flows
ruby benchmarks/perfomance/flow/success_results.rb
ruby benchmarks/perfomance/flow/failure_results.rb
```

Memory profiling:

```sh
./benchmarks/memory/use_case/success/with_transitions/analyze.sh
./benchmarks/memory/use_case/success/without_transitions/analyze.sh
./benchmarks/memory/flow/success/with_transitions/analyze.sh
./benchmarks/memory/flow/success/without_transitions/analyze.sh
```

### Disabling runtime checks

Set `disable_runtime_checks = true` for an extra few percent in production once your test suite has exercised the code paths:

```ruby
Micro::Case.config { |c| c.disable_runtime_checks = true }
```

Measured wins (see [`benchmarks/perfomance/runtime_checks/compare.rb`](https://github.com/serradura/u-case/blob/main/benchmarks/perfomance/runtime_checks/compare.rb)) are JIT-dependent: within noise on stock Ruby, ~3–5% on Ruby 3.2 +YJIT, ~4–7% on Ruby 4.0 +PRISM.

### Comparisons

Side-by-side implementations of the same use case in other libraries:

- [Interactor](https://github.com/serradura/u-case/blob/main/comparisons/interactor.rb)
- [u-case](https://github.com/serradura/u-case/blob/main/comparisons/u-case.rb)

[⬆️ Back to Top](#table-of-contents-)

## Examples

### An end-to-end sign-up flow

Three use cases composed into a transactional flow, using `accept:` validation, result contracts, and hooks:

```ruby
class NormalizeParams < Micro::Case
  attribute :params, accept: Hash

  results do |on|
    on.success(result: [:name, :email])
    on.failure(:invalid_params)
  end

  def call!
    name  = params[:name].to_s.strip
    email = params[:email].to_s.strip.downcase

    return Failure(:invalid_params) if name.empty? || email.empty?

    Success result: { name: name, email: email }
  end
end

class CreateUser < Micro::Case
  attributes :name, :email

  results do |on|
    on.success(result: [:user])
    on.failure(:invalid_user)
  end

  def call!
    user = User.create(name: name, email: email)

    return Failure(:invalid_user, result: { errors: user.errors }) if user.errors.any?

    Success result: { user: user }
  end
end

class CreateProfile < Micro::Case
  attributes :user

  results do |on|
    on.success(result: [:profile])
    on.failure(:invalid_profile)
  end

  def call!
    profile = Profile.create(user_id: user.id)

    return Failure(:invalid_profile, result: { errors: profile.errors }) if profile.errors.any?

    Success result: { profile: profile }
  end
end

SignUp = Micro::Cases.flow(transaction: true, steps: [
  NormalizeParams,
  CreateUser,
  CreateProfile
])

SignUp
  .call(params: { name: 'Ada', email: 'ADA@EXAMPLE.com' })
  .on_success                   { |r| render json: { user_id: r[:user].id } }
  .on_failure(:invalid_params)  {     render status: 422 }
  .on_failure(:invalid_user)    { |r| render status: 422, json: { errors: r[:errors] } }
  .on_failure(:invalid_profile) { |r| render status: 422, json: { errors: r[:errors] } }
```

If `CreateProfile` fails, the `User` row inserted by `CreateUser` is rolled back — that's `transaction: true` doing its job. The result surfaces `:invalid_profile`, the hook fires, and the database is left clean.

### More examples

- **[Users creation flow](https://github.com/serradura/u-case/blob/main/examples/users_creation)** — sanitize, validate, persist; demonstrates every composition style.
- **[Rails app (API)](https://github.com/serradura/from-fat-controllers-to-use-cases)** — different architectures across commits; the last one uses `Micro::Case` for the business logic.
- **[CLI calculator](https://github.com/serradura/u-case/tree/main/examples/calculator)** — Rake tasks demonstrating user-input handling and failure-type-driven control flow.
- **[Rescuing exceptions](https://github.com/serradura/u-case/blob/main/examples/rescuing_exceptions.rb)** — patterns for exception handling inside use cases.

[⬆️ Back to Top](#table-of-contents-)

## Going further with `u-attributes`

`Micro::Case`'s `attribute` / `attributes` macros come from [`u-attributes`](https://github.com/serradura/u-attributes), and every feature that gem supports is available on every use case. Two patterns worth knowing — **both require [`u-attributes >= 3.1`](https://github.com/serradura/u-attributes)**:

### Nested attributes (block form)

Declare an attribute that itself has attributes — useful when your input is a structured object instead of a flat hash. `accept:` on the inner attributes still participates in the parent's `:invalid_attributes` failure:

```ruby
class CreateOrder < Micro::Case
  attribute :id, accept: Integer

  attribute :customer do
    attribute :name,  accept: String
    attribute :email, accept: String
  end

  def call!
    Success result: { order: Order.create!(id: id, customer_id: customer.id) }
  end
end

CreateOrder
  .call(id: 42, customer: { name: 'Ada', email: 'ada@example.com' })
  .success? # => true

CreateOrder
  .call(id: 42, customer: { name: 42, email: 'ada@example.com' })
  .type     # => :invalid_attributes
```

The nested hash is accessible as `customer.name`, `customer.email`.

### Accepting another attribute class

`accept:` can target another class — incoming hashes auto-coerce into instances of it:

```ruby
class CreateProfile < Micro::Case
  Address = Micro::Attributes.new do
    attribute :city,   accept: String
    attribute :postal, accept: String
  end

  attribute :name,    accept: String
  attribute :address, accept: Address

  def call!
    Success result: { profile: Profile.create!(name: name, address: address.to_h) }
  end
end

CreateProfile.call(
  name: 'Rodrigo',
  address: { city: 'Rio', postal: '20000-000' }
)
# => Success — `address` is an Address instance inside `call!`
```

For defaults, `allow_nil:`, custom validators, and the rest of the feature set, see the [`u-attributes`](https://github.com/serradura/u-attributes) README.

[⬆️ Back to Top](#table-of-contents-)

## Development

After checking out the repo, run `bin/setup` to install dependencies and refresh appraisals. Then `bundle exec rake test` runs the default suite, `bundle exec appraisal <name> rake test` runs one Rails appraisal (see `Appraisals`), and `bundle exec rake matrix` runs the full local matrix for the active Ruby. `bin/console` opens an interactive prompt.

To install onto your local machine, run `bundle exec rake install`. To release a new version, bump `lib/micro/case/version.rb`, then `bundle exec rake release` (creates the git tag, pushes commits and tags, pushes the `.gem` to [rubygems.org](https://rubygems.org)).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/serradura/u-case. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](https://contributor-covenant.org) code of conduct.

## License

Available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Micro::Case project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/serradura/u-case/blob/main/CODE_OF_CONDUCT.md).
