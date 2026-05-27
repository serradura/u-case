# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **Note:** This gem was originally published as `u-service` (versions 0.1.0 – 1.0.0) and renamed to `u-case` starting with `u-case 1.0.0` on 2019-09-15.

## [Unreleased]
### Added
- `Micro::Case::Result::Success.new(data:, type:, use_case:)` and `Micro::Case::Result::Failure.new(data:, type:, use_case:)` for fabricating result instances in tests without running a real use case (closes #6). `Success.to_yield(...)` and `Failure.to_yield(...)` return a `Micro::Case::Result::Wrapper` for stubbing block-form `Micro::Case.call(input) { |on| ... }` consumers (e.g. with RSpec's `and_yield` or Mocha's `yields`). Defaults: `data: {}`, `type: :ok` for `Success` / `type: :error` for `Failure`, and a lazily-memoised anonymous `Micro::Case` instance for `use_case:` (one allocation per process; passing an explicit `use_case:` still works). Constants are **modules**, not classes — `result.class == Micro::Case::Result` (no subclass surface), and the call routes through `Result#__set__` so `result_type!` / `result_data!` / `micro_case_instance!` participate normally, including the `disable_runtime_checks = true` no-op path. Strictly additive: no existing API moves or changes shape; user-land shims that reopen `Micro::Case::Result` with the same `Success` / `Failure` modules continue to work.
- **Opt-in require.** The factories are NOT auto-required by the gem — `require 'u-case'` (or any of its constituent files) leaves the constants undefined. Add `require 'micro/case/with_test_doubles'` to your `spec/spec_helper.rb` or `test/test_helper.rb` to load them. Production load paths are unaffected.
- `examples/test_doubles/` — runnable example with `Affiliates::FetchEmail` (collaborator), `Affiliates::SendInvite` (return-value consumer) and `Affiliates::DeliverReferral` (block-form consumer), plus paired RSpec and Minitest+Mocha suites demonstrating both `Result::Success.new` / `Result::Failure.new` (RSpec's `and_return`, Mocha's `returns`) and `.to_yield` (RSpec's `and_yield`, Mocha's `yields`).
- READMEs (EN + pt-BR) document the new factories in a **Testing with test doubles** section, including the opt-in `require 'micro/case/with_test_doubles'` line and the two minimal stubbing examples.

## [5.7.1] - 2026-05-26
### Added
- A `[!IMPORTANT]` GitHub alert at the top of both READMEs (EN + pt-BR) surfacing the **no-breaking-changes-to-the-API** policy (see [issue #131](https://github.com/serradura/u-case/issues/131#issuecomment-4531231882)) — the gem will remain a stable, backward-compatible foundation; redesigns belong in [`solid-process`](https://github.com/solid-process/solid-process). The alert also clarifies that major version bumps happen only when a Ruby or Rails version is dropped from the supported matrix (per SemVer dependency-floor semantics).

### Changed
- English and pt-BR READMEs restructured for clearer onboarding and reference. Top-level reorganization: added a **Quick start** section (basic use case + pattern matching consumption + transactional flow + inline `transaction { ... }` helper) and a refreshed "What you get" value-prop, promoted result contracts and pattern matching out of nested Result subsections, grouped flows / internal-step `Result#then` chains / transactions under a new "Composing use cases" umbrella, framed `accept:` / `reject:` as the default validation story with ActiveModel as the opt-in Rails-integration layer, condensed the benchmarks section, and added an inline end-to-end sign-up flow under Examples. Heading style is now uniformly declarative (FAQ-style "Is it possible…?" / "How to…?" titles removed) and several `[⬆️ Back to Top]` link occurrences were thinned out. Documented previously-undocumented `Micro::Case.config.set_activemodel_validation_errors_failure`. Both READMEs are in lockstep. No API or behavior changes — purely documentation.
- New top-level **Going further with `u-attributes`** section in both READMEs covering nested attributes (block form, e.g. `attribute :customer do … end`) and `accept:` targeting another `Micro::Attributes`-based class for auto-coercion of incoming hashes. The Quick start section's closing pointer routes readers here for the deep dive.
- All math-based example classes throughout both READMEs were rewritten with realistic, non-math use cases that span the same API surface: `Multiply` / `Divide` / `Double` / `Add` / `Square` / `Add2` / `Add3` / `SumHalf` / `DoSomeSum` / `ForbidNegativeNumber` / `ConvertTextToNumber(s)` are replaced by `Slugify`, `ValidateEmail`, `FormatGreeting`, `ParseJsonPayload`, `FetchUser`, `MergeTags`, `PublishPost`, `CreateComment`, `ChangePassword`, `FindActiveUser` / `GenerateInviteToken` / `FindUser`, `CreatePost` / `CountPosts`, the `Steps` module's tag-normalization pipeline (`ParseTags` / `Downcase` / `StripHashPrefix` / `RemoveDuplicates`), `CleanTags` + `ParseTagsString` + `JoinTagsArray`, and `CreateBlogPost` + `CapitalizeTitle`. Same teaching points; idioms a Rails/Ruby reader recognizes on first glance.

## [5.7.0] - 2026-05-25
### Added
- Pattern matching support on `Micro::Case::Result` via `#deconstruct` and `#deconstruct_keys` (closes #146). Purely additive — no existing API is changed or removed. `#deconstruct` returns `[status, type, data]` where `status` is `:success` or `:failure`, so array patterns like `in [:failure, :invalid_attributes, { invalid_attributes: errors }]` can use the status as a discriminant — mirroring how libraries with separate `Success`/`Failure` classes are pattern-matched, even though `Micro::Case::Result` is a single class. `#deconstruct_keys` exposes `:type`, `:data`, `:result` (alias of `:data` that matches the `Success(result: …)` creation-site vocabulary), `:use_case` and `:transitions` on every result; `:success` is present only on success results and `:failure` only on failure results, and both carry the result `type` symbol as their value so `in { failure: :invalid_attributes }` works. `#deconstruct_keys` honors Ruby's `keys` argument and only computes the requested entries (relevant for `:transitions`, which allocates a duped array).
- READMEs (EN + pt-BR) document the new pattern under the `Micro::Case::Result` section, including the key table, the `data:` / `result:` alias note, and the intentional shape difference between `#deconstruct` (`[status, type, data]`, used by pattern matching) and `#to_ary` (`[data, type]`, unchanged, used by multi-assignment).

## [5.6.0] - 2026-05-24
### Added
- `Micro::Cases.flow(transaction: true, steps: [...])` and `Micro::Cases.safe_flow(transaction: true, steps: [...])` to wrap an entire flow in an `ActiveRecord::Base.transaction`. Any step that returns a failure (or, in `safe_flow`, raises) triggers an `ActiveRecord::Rollback`. The same kwargs are accepted by the class-level macro: `class MyCase < Micro::Case; flow(transaction: true, steps: [...]); end` (closes #44).
- `Micro::Cases::Error::TransactionAdapterMissing`, raised on the first call when `transaction: true` is used without `ActiveRecord::Base` loaded. The gem still does **not** require `active_record` automatically — applications must load it themselves.
- Three new methods on `Micro::Case::Check` — `flow_steps_kwarg!`, `transaction_kwarg!` and `activerecord_loaded!` — so the transaction-flow validation participates in `config.disable_runtime_checks = true`. All inline `raise ArgumentError` / `raise Error::TransactionAdapterMissing` sites in `lib/micro/cases.rb`, `lib/micro/case.rb` and `lib/micro/cases/flow.rb` now route through `Micro::Case.check`, matching the convention introduced in 5.4.0.
- Multi-database support for transactions. Use cases can declare which ActiveRecord class should own their transactions with the new `transaction with: SomeRecord` class macro (inherited like `flow` / `attributes`); the inline `Micro::Case#transaction(with:)` helper and the flow-level `transaction: { with: SomeRecord }` kwarg share the same `with:` vocabulary. `transaction: true` remains the "use the default" shortcut. A new `Micro::Case.config.default_transaction_class { ApplicationRecord }` callback (block or lambda) lets Rails apps configure the abstract record once in an initializer; the default is `-> { ::ActiveRecord::Base }`. Two new checks (`transaction_owner!`, `transaction_class_callback!`) route the new validations through `Micro::Case::Check`. Resolution order at transaction-open time: call-site `with:` override > host case's `transaction with:` macro > global callback.

### Changed
- `Micro::Case#transaction` instance helper signature changed from `transaction(adapter = :activerecord)` to `transaction(adapter = nil, with: nil)`. The pre-5.6.0 form `transaction(:activerecord) { ... }` keeps working as an alias for `transaction { ... }`; any other positional value raises `ArgumentError` (the legacy helper only accepted `:activerecord`).
- Transaction owners (`with:` on the inline helper, on the class macro, and on the flow `transaction:` kwarg) must be subclasses of `ActiveRecord::Base`. Non-AR classes are rejected with `ArgumentError` — the gem's rollback signaling hardcodes `ActiveRecord::Rollback`, so non-AR transaction objects (Sequel, custom adapters) are explicitly out of scope. The class-macro validation runs at class-eval time when AR is already loaded; otherwise it defers to runtime so initializer load order doesn't break declarations.
- `Micro::Cases.flow([], steps: [...])` and `safe_flow([], steps: [...])` now treat an empty positional array as "no positional collection" instead of raising the "both provided" error.
- `Check::Disabled#transaction_kwarg!` now returns `nil` (no transaction) for unrecognized inputs instead of silently coercing them to `true`. A typo under `disable_runtime_checks = true` therefore stays non-transactional rather than upgrading to a real transaction against the default class.
- READMEs (EN + pt-BR) now document `Micro::Case#transaction` (the inline `transaction { ... }` helper available inside `call!`) and the new flow-level `transaction:` kwarg, including behavior notes for nested transactions (AR-joined semantics), the `Flow`-instance flattening footgun, and the difference between plain and safe transactional flows on exceptions.
- READMEs (EN + pt-BR) now describe **internal steps** — `Result#then(:symbol)` / `Result#then(method(:name))` / `Result#then(-> { })` / `|` — as u-case's third way of composing a flow, alongside `Micro::Cases.flow` and the class-level `flow` macro. The new section spells out the data-flow contract (each link's `Success` result becomes the next link's kwargs), the transition recording behavior, and the fact that internal steps are fully composable inside outer flows and transactional flows.
- Transaction composition matrix test suite (`test/micro/cases/flow/transaction_composition_matrix_test.rb`) crossing all 8 wrappers (4 non-tx × 4 tx) at level 1 and level 2 of nesting, plus deep-rollback cases, behavioral parity assertions (tx vs non-tx `result.data` / `transitions` / `accessible_attributes` are equal), and `Result#then` accumulation across a tx boundary.
- Internal-steps-in-flows test suite (`test/micro/cases/flow/internal_steps_in_flows_test.rb`) that drops symbol-, method- and lambda-based internal-step use cases into every flow wrapper (non-tx and tx) and asserts behavioral parity with the leaf-pair equivalent: accumulated `result.data`, total transition count (3 internal + 3 outer = 6 for a 5-step chain), interleaved transition order, and rollback of internal-step database writes when a `Failure` is returned from inside the internal chain under a transactional outer flow.

## [5.5.0] - 2026-05-24
### Added
- `Micro::Case.results { |on| ... }` macro to declare a results contract — the allowed `Success`/`Failure` types and the result keys each one requires. `Success(...)` / `Failure(...)` calls that use an undeclared type now raise `Micro::Case::Error::UnexpectedResultType`; calls missing a declared required key raise `Micro::Case::Error::MissingResultKeys`. Use cases without a `results` block keep their previous unrestricted behavior. The check routes through `Micro::Case::Check#results_contract!`, so it is also bypassed when `config.disable_runtime_checks = true` (closes #22). Carve-outs so contracts don't break neighbouring features:
  - Framework-generated `__failure_from_attributes_errors` (the auto-failure produced when `accept:`/`reject:` or ActiveModel validation rejects an input) bypasses the contract — it goes directly to `__set__` rather than through `Failure(...)` — so combining `results` with attribute validation no longer requires declaring `:invalid_attributes`.
  - Rescued exceptions in `Micro::Case::Safe` (which produce `Failure(result: exception)`) bypass the contract.
  - Result hashes with `String` keys are matched against the contract's symbolised required keys — `Success(result: { 'value' => 1 })` satisfies `result: [:value]`, mirroring `Result`'s own tolerance for either key type.
  - Non-`Hash` / non-`Symbol` `result:` arguments fall through to the existing `Micro::Case::Error::InvalidResult` ("must be a Hash") instead of being misreported as missing keys.
  - Non-`Symbol` `type` arguments fall through to `Micro::Case::Error::InvalidResultType` instead of being misreported as undeclared.
  - `Micro::Case.results` raises `ArgumentError` when called on the abstract base class itself, so a stray declaration cannot leak a contract to every subclass in the process.

## [5.4.0] - 2026-05-24
### Added
- `Micro::Case.config.disable_runtime_checks` config (default `false`) to skip the gem's internal argument/contract checks for better performance in production. All checks are consolidated in `Micro::Case::Check::Enabled` (the default) and `Micro::Case::Check::Disabled` (no-ops with the same signature); the active module is swapped via `Micro::Case.check`. Measured throughput win is JIT-dependent: within noise on stock Ruby (no JIT), ~3–5% on Ruby 3.2 +YJIT, ~4–7% on Ruby 4.0 +PRISM (see `benchmarks/perfomance/runtime_checks/compare.rb`). Closes #45.
- `benchmarks/perfomance/runtime_checks/` — per-mode subprocess benchmark (`checks_enabled.rb`, `checks_disabled.rb`, `compare.rb`) demonstrating the toggle's perf effect across Ruby versions and JIT modes.

## [5.3.1] - 2026-05-23
### Added
- This `CHANGELOG.md`, covering the full history of the gem (from `u-service 0.1.0` through `u-case 5.3.1`) following the [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) spec.
- `changelog_uri`, `source_code_uri` and `bug_tracker_uri` entries in `spec.metadata` so RubyGems.org surfaces direct links from the gem page and tools like `bundle outdated` can deep-link to the changelog.

## [5.3.0] - 2026-05-23
### Added
- `Micro::Case.config.disable_safe_features` config (default `false`) to forbid `Safe` usage so a codebase can standardize on plain `rescue` for exception handling. When enabled, subclassing `Micro::Case::Safe`, calling `Micro::Cases.safe_flow(...)` or `Micro::Case::Result#on_exception` raise `Micro::Case::Error::SafeFeaturesDisabled` (closes #47, #141).
- README "Safe" section now documents how to opt out via `disable_safe_features`.

## [5.2.1] - 2026-05-23
### Fixed
- Propagate the parent `Micro::Case::Result` when invoking a class-level inner `flow ...`. Previously, transitions accumulated on the parent `Result` were silently dropped whenever a use case with an inner flow was invoked from another flow or chained via `Result#then`. Behavior is now unified across `Micro::Cases.flow`, `Micro::Cases.safe_flow`, `class < Micro::Case; flow ...; end` and `class < Micro::Case::Safe; flow ...; end` regardless of nesting or chaining.

### Added
- `ruby-lsp` as a development dependency on Ruby >= 3.0.
- Flow composition matrix test suite covering all four flow constructors at 4+ nesting levels, every `Result#then` / class-level `.then` variant, the `[UseCase, defaults]` step shape, and self-referential inner flows.

## [5.2.0] - 2026-05-23
### Changed
- `accept:` / `reject:` attribute validation from `u-attributes` is now enabled by default. Use cases automatically fail with `:invalid_attributes` when an attribute is rejected. When combined with ActiveModel validation, `accept` runs first and ActiveModel validation only runs if every attribute is accepted (closes #90).
- Widened `u-attributes` runtime dependency to `>= 2.8, < 4.0`. On `u-attributes` 2.8 (which does not ship the Accept feature) the base behavior is unchanged; on 3.x the Accept feature is wired in automatically.
- READMEs (EN + pt-BR) now document the `accept:` / `reject:` attribute validation flow.

### Removed
- The short-lived `Micro::Case::Config#enable_attributes_accept` toggle introduced earlier in this release cycle. It never had a working opt-out: load-time switching was defeated by load order (Rails initializers run after `require 'u-case'`) and the runtime flag only suppressed auto-failure while still mixing in `Accept`. Users who don't want the auto-failure can simply omit `accept:` / `reject:` from their attribute declarations.

### Fixed
- Gate the `minitest` development dependency on Ruby version.

## [5.1.0] - 2026-05-23
### Added
- `Micro::Case::Result#keys`, `#fetch` and `#fetch_values` for `Hash`-like access to the result data (PR #127, thanks @tomascco).
- pt-BR README documentation for the new `Result` methods.

## [5.0.0] - 2026-05-23
### Changed
- **BREAKING:** Bumped minimum Ruby to **2.7.0** (Ruby 2.2 – 2.6 are EOL and no longer supported).
- Widened runtime dependency upper bounds so the 5.0.0 line resolves against the latest releases of its siblings: `kind` is now `>= 5.6, < 7.0` and `u-attributes` is now `>= 2.7, < 4.0`.
- Modernized the CI/test runner via Appraisal (mirroring the `solid-process` layout): per-Rails subdirectory gemfiles were replaced with an `Appraisals` file gated on `RUBY_VERSION`, the GitHub Actions matrix now covers Ruby 2.7 – 4.0+head with conditional Rails steps, and the `ENABLE_TRANSITIONS` true/false axis is preserved as a CI matrix dimension.
- Switched code coverage reporting from CodeClimate to **Qlty** (OIDC-based upload, badges updated in both READMEs).
- README polish: new header/badge layout, Ruby × Rails support matrix, refreshed compatibility table, and pt-BR typo fixes.

### Added
- Appraisal-generated gemfiles for **Rails 8.1** and **Rails edge**.
- `bin/matrix` script and `rake matrix` task to run the full local test matrix.
- `bin/setup` script.

### Removed
- Per-Rails subdirectory gemfiles under `gemfiles/rails_5.2…rails_edge/` (replaced by Appraisal).
- `pry-byebug` from the test helper (dev-only convenience, no longer required).

### Security
- Hardened the GitHub Actions workflow per `zizmor` findings: least-privilege `contents: read` permissions on the test job and `persist-credentials: false` on `actions/checkout` (#135).

## [4.5.2] - 2022-12-05
### Added
- Add Ruby 3.1 to the test matrix.

### Changed
- Migrate CI from Travis CI to GitHub Actions.

### Fixed
- Rename `Micro::Case::Utils::Hashes.respond_to?` to `hash_respond_to?` so it no longer overrides Ruby's default `respond_to?`.
- Return the generated flow-step class explicitly so flow definitions stay compatible with Ruby 3.1.
- Restore `Micro::Cases.map` behavior on Ruby 2.5 (avoid `return` inside the inner lambda).

## [4.5.1] - 2021-06-08
### Fixed
- Stop invoking `on_unknown` after a matching `on_exception` hook has already handled the result.

## [4.5.0] - 2021-06-08
### Changed
- Bump the required `kind` runtime dependency to `>= 5.6, < 6.0`.

## [4.4.0] - 2021-06-08
### Changed
- Optimize `Micro::Case::With::ActiveModelValidation`: validations now run lazily via `errors.present?` during the call instead of eagerly in `initialize`, and the redundant `respond_to?(:run_validations!)` check is gone.

## [4.3.0] - 2021-02-22
### Added
- `Micro::Case#Check(type = nil, result: nil) { ... }` helper that turns a truthy/falsy block into a typed `Success`/`Failure` (defaulting to `:check_ok` / `:check_fail`).
- `Result#then` now accepts a `Symbol`/`String`, calling the matching instance method on the source use case as the next step.

### Changed
- Bump runtime dependencies: `kind` to `>= 4.0, < 6.0` and `u-attributes` to `>= 2.7, < 3.0`.
- Make the test suite Ruby 3.0 compatible.

### Removed
- Stop registering `Micro::Case` and `Micro::Case::Result` with `Kind::Types`, dropping the `Kind::Of::Micro::Case` / `Kind::Of::Micro::Case::Result` validators.

## [4.2.2] - 2020-12-04
### Fixed
- Fix the output returned when invoking a use case with a block — the block's wrapper output is now propagated as the call's return value via the new `Result::Wrapper#output`.

## [4.2.1] - 2020-10-21
### Fixed
- Make `Micro::Case`, `Micro::Case::Result`, and `Micro::Cases::Flow` `#inspect` strings start with `#<...>` and collapse recursive inspect output to `#<Class: ...>`.

## [4.2.0] - 2020-10-19
### Added
- `Micro::Case#transaction(adapter = :activerecord) { ... }` helper that wraps a block in `ActiveRecord::Base.transaction` and rolls back when the yielded result is a failure.

## [4.1.1] - 2020-10-15
### Fixed
- Fix `Micro::Case#inspect` when the class declares an inner flow — recursion is now guarded with a thread-local key so nested inspections no longer loop.

## [4.1.0] - 2020-10-14
### Added
- Allow calling a use case or flow inside another use case via the private `call(use_case, defaults = {})` helper, automatically forwarding attributes/accessible attributes.
- Allow invoking a use case or flow with a block (`MyCase.call(...) do |result| result.success { ... }; result.failure { ... }; end`) backed by a new `Micro::Case::Result::Wrapper` (with `success`, `failure`, and `unknown` handlers).
- `Micro::Cases.map(...)` / `Micro::Cases::Map` to fan out the same input across multiple use cases and collect their results.
- Allow dependency injection in both static (`flow A, [B, dep: ...], C`) and inner-flow definitions via `[UseCase, defaults_hash]` tuples.
- `Micro.case?(arg)` predicate (in addition to the existing `Micro.case_or_flow?`).
- Track an "unknown" result state and expose `Result#unknown?` plus the `on_unknown` hook so unhandled success/failure types can be caught.
- `Micro::Cases::Error` used for invalid use-case errors raised by flows and `Cases::Map`.
- New internals: `Micro::Cases::Utils` (`MapUseCases`, `IsAValidUseCase`, …) and a `Micro::Case::Utils::Hashes.stringify_keys` helper.

### Changed
- `Micro::Case.new` is now a private class method — use `.call` / `.__new__` (internal) instead of constructing instances directly.
- Drop the `u-attributes` `:initialize` and `:diff` extensions; `Micro::Case` now `include Micro::Attributes` directly.
- Refine `Result#inspect` to omit the `transitions=` segment when transitions are disabled.

### Fixed
- Fix inner flows declared with an array argument.

## [4.0.0] - 2020-08-20
Major rewrite. The headline shifts:
- `Micro::Case::Result` now starts in an "unknown" state and only transitions to handled once `on_success`/`on_failure` matches, unlocking the upcoming `on_unknown` workflow.
- The gem now requires the brand-new `u-attributes ~> 2.0` runtime, which changes how attribute inheritance works for `Micro::Case` subclasses.
- The `Micro::Case::Result` transitions mapper now always defaults to `Transitions::MapEverything`.

### Added
- `Micro::Case::Result#to_sym` returning `:success` or `:failure`.

### Changed
- **BREAKING:** Bump runtime dependency `u-attributes` from `~> 1.1` to `~> 2.0`; switch the internal include from `Micro::Attributes.without(:strict_initialize)` to `Micro::Attributes.with(:initialize, :diff)` and update the inheritance hook accordingly.
- Refactor `Micro::Case::Result` construction so `transitions_mapper` defaults to `Transitions::MapEverything` directly and `MapEverything` uses `result.to_sym` instead of an intermediate local.
- Update gem summary/description to "Represent use cases in a simple and powerful way while writing modular, expressive and sequentially logical code."

### Removed
- Remove the `--pre` flag references from the docs/install instructions now that 4.x ships as a stable release.

## [3.1.0] - 2020-08-17
### Added
- `Micro::Case#apply` as a private alias for `#method` to make internal step composition more idiomatic.
- `Micro::Case::Result::Transitions` extracted as a dedicated class to model the sequence of steps executed by a use case / flow.

### Changed
- Freeze `Micro::Case::Result#data` so the accumulated payload cannot be mutated by callers.
- Internal refactor of `Micro::Case::Result` and minor README/translation polish.

### Fixed
- Improve handling and error feedback when `Micro::Case::Result#then` is invoked with an invalid argument.

## [3.0.0] - 2020-08-14
Major rewrite consolidating nine release candidates. Highlights:

### Added
- New flow builders `Micro::Cases.flow(...)` and `Micro::Cases.safe_flow(...)` replacing the previous `Micro::Case::Flow()` / `Micro::Case::Safe::Flow()` constructors.
- `Micro::Case::Result#data` holding the accumulated step output, plus `Result#[]`, `Result#values_at`, `Result#key?`, `Result#value?` and `Result#slice` for ergonomic data access.
- `Micro::Case::Result#transitions` exposing the ordered history of steps executed during a use case / flow.
- `Micro::Case.config` for global configuration (e.g. enabling/disabling transitions tracking, ActiveModel validation).
- `Micro::Case.then` and `Micro::Cases::Flow#then` so use cases and flows can be chained.
- `Micro::Case::Result#then` / `Result#|` accept a `Micro::Case` class, a flow, a method instance or a block, and accumulate data across the chain.
- Declare a use case's steps by referencing its own private methods.
- Top-level introspection helpers `Micro.case?` and `Micro.case_or_flow?`.
- Success results expose the use case instance that produced them.

### Changed
- **BREAKING:** `Success`/`Failure` results are now declared via the `result:` keyword argument instead of a block (e.g. `Success(result: { ... })`).
- **BREAKING:** Result payloads must be a `Hash`; the result `type` must be a `Symbol`; failure results coming from an `Exception` are normalized accordingly. Defining an invalid success/failure now raises an explicit error.
- **BREAKING:** Static use case methods renamed to the new convention (e.g. `Micro::Case.call!`, `.__new!`) and inner flow constant renamed from `Flow_Step` to `Self`.
- Bumped the `kind` gem to the next major version.
- Only two ways to define a flow are now supported; the legacy `Flow::Reducer` was removed.

### Removed
- **BREAKING:** `Micro::Case#call` instance method — use cases are invoked via the class-level API.
- **BREAKING:** `Micro::Case::Flow()` and `Micro::Case::Safe::Flow()` constructors (replaced by `Micro::Cases.flow` / `Micro::Cases.safe_flow`).
- The deprecated `u-case/with_validation` shim file.

### Fixed
- Internal steps and flow execution behave correctly when result transitions tracking is disabled.
- Internal steps that receive a method instance now use keyword arguments (`**`) consistently.

## [3.0.0.rc9] - 2020-08-14
### Changed
- Internal steps that receive a method instance now use keyword arguments for parameter passing.

## [3.0.0.rc8] - 2020-08-14
### Fixed
- Flow execution when result transitions are disabled.
- Internal steps that receive a method instance now use the double-splat operator.

## [3.0.0.rc7] - 2020-08-13
### Fixed
- Internal steps when result transitions are disabled.

## [3.0.0.rc6] - 2020-08-12
### Added
- `Micro::Case::Result#then` / `Result#|` accept a method instance, in addition to a block or use case.

### Changed
- `Micro::Case::Result#then` / `Result#|` now accumulate data across the chain.
- Default branch references migrated from `master` to `main`.

## [3.0.0.rc5] - 2020-08-12
### Added
- `Micro::Case.then` and `Micro::Cases::Flow#then` so use cases and flows can be chained.
- `Micro::Case::Result#key?`, `Result#value?` and `Result#slice` for ergonomic data access.

### Changed
- Renamed inner flow constant `Flow_Step` to `Self`.
- Refactored `Micro::Cases::Flow` input handling.
- pt-BR README translation introduced; READMEs, logo and assets refreshed.

## [3.0.0.rc4] - 2020-08-02
### Added
- Declare use case steps by referencing private methods of the use case.
- Top-level introspection helpers `Micro.case?` and `Micro.case_or_flow?`.

### Changed
- **BREAKING:** Static public methods of `Micro::Case` renamed to the new convention.
- Validate the output of lambdas passed to `Micro::Case::Result#then` / `Result#|`.
- Result transitions now also include the steps coming from internal step methods.

### Removed
- **BREAKING:** `Micro::Case#call` instance method.

## [3.0.0.rc3] - 2020-07-29
### Added
- `Micro::Case.config` for global configuration of the library (e.g. transitions tracking, ActiveModel validation).
- Success results now expose the use case instance that produced them.

## [3.0.0.rc2] - 2020-07-28
### Changed
- Prepare for the next major version of the `kind` gem.
- Refactor `Micro::Case::Error::InvalidResult` and improve the error message raised when a use case returns the wrong result type.

### Removed
- The deprecated `lib/u-case/with_validation.rb` shim.

## [3.0.0.rc1] - 2020-07-21
### Added
- New flow builders `Micro::Cases.flow(...)` / `Micro::Cases.safe_flow(...)`.
- `Micro::Case::Result#data` exposing the accumulated payload, plus `Result#[]` and `Result#values_at`.
- `Micro::Case::Result#transitions` exposing the ordered history of executed steps.
- Result payloads can now be initialized from a `Hash`, `Symbol` or `Exception`.

### Changed
- **BREAKING:** `Success`/`Failure` results are now declared via the `result:` keyword argument instead of a block.
- **BREAKING:** `Micro::Case::Result#then` now yields the result itself and returns the block's value.
- **BREAKING:** Only two ways to define a flow are supported; the legacy `Flow::Reducer` was removed.
- Defining an invalid success/failure result now raises an explicit error.

### Removed
- **BREAKING:** `Micro::Case::Flow()` and `Micro::Case::Safe::Flow()` constructors — use `Micro::Cases.flow` / `Micro::Cases.safe_flow` instead.

## [2.6.0] - 2020-07-07
### Added
- New behavior for `Micro::Case::Result#then` to chain another use case from a result.

### Fixed
- `Micro::Case::Result#transitions` no longer produces incorrect/duplicated entries when chaining via `#then`.

## [2.5.0] - 2020-06-26
### Added
- `Micro::Case::Result#on_exception` hook to handle exceptions raised inside a use case.

### Changed
- Forbid inheritance from a use case that defines an inner flow (raises an explicit error instead of silently misbehaving).

## [2.4.0] - 2020-06-26
### Added
- New file `u-case/with_activemodel_validation` so projects can opt into the ActiveModel-backed validation flavor explicitly.
- `Micro::Case::Utils` helper module.
- `Kind.of.Micro::Case::Result` type checker (via the new `kind` runtime dependency).
- `Micro::Case::Result#transitions` exposing the step-by-step history of a flow, including `:accessible_attributes` for each step.
- `Micro::Case::Result.disable_transition_tracking` configuration to opt out of transition tracking.
- New built-in support for validations via `Kind::Validator` (alongside ActiveModel).
- The use case instance is now exposed on successful results.

### Changed
- `kind` is now a runtime dependency (bumped to `~> 3.0`).
- `require "u-case/with_validation"` now also loads the ActiveModel-based validation layer for backward compatibility.

## [2.3.1] - 2019-12-29
### Fixed
- Use-case validation no longer breaks when the class also declares a flow.

## [2.3.0] - 2019-12-17
### Added
- `Micro::Case::Result#then` to pipe a successful result into another use case (or block).
- Clearer error messages raised by `Micro::Case` when misused.

## [2.2.0] - 2019-12-12
### Added
- The flow definition (`flow ...`) can now be declared independently of the attribute declarations, making class layout more flexible.

## [2.1.1] - 2019-12-12
### Fixed
- Flow execution when a participating use case declares validations.

## [2.1.0] - 2019-12-12
### Added
- A `Micro::Case` subclass can declare its own internal flow and include itself in that flow.

### Deprecated
- The `Micro::Case::Flow` mixin — declare flows directly on the use case class instead.

## [2.0.0] - 2019-11-19
First stable 2.0 release. Includes everything from the 2.0.0.pre series plus:

### Added
- Per-class opt-out from the automatic validation step (`disable_auto_validation`).

## [2.0.0.pre.4] - 2019-11-19
### Changed
- A flow now accumulates the success results of each step and feeds the merged data as input into the next use case.
- Renamed the custom test assertion helpers for `Micro::Case::Result` objects (final naming).

## [2.0.0.pre.3] - 2019-11-14
### Fixed
- `Micro::Case::Safe.Flow()` definition.
- `on_failure` without an explicit type now exposes a `Micro::Case::Result::Data` value instead of leaking internals.

## [2.0.0.pre.2] - 2019-11-13
### Changed
- New API for defining flows that operate over collections.

## [2.0.0.pre] - 2019-11-12
### Changed
- **BREAKING:** `Micro::Case::Base` was merged into `Micro::Case` — inherit from `Micro::Case` directly.
- **BREAKING:** `Micro::Case::Flow::Safe` was renamed to `Micro::Case::Safe::Flow`.
- Filenames using the old `pipeline` terminology were renamed to `flow`.

### Added
- New custom Minitest assertions for `Micro::Case::Result` (`assert_success_result`, `assert_failure_result`, `assert_result`).

## [1.1.0] - 2019-10-04
### Changed
- Validation failure results now expose their errors as a `Hash` for consistent destructuring.

## [1.0.0] - 2019-09-15
First release under the `u-case` name (renamed from `u-service`).

### Changed
- **BREAKING:** Gem renamed from `u-service` to `u-case`.
- **BREAKING:** `Micro::Service` namespace renamed to `Micro::Case` — update all references (`Micro::Service::Base` → `Micro::Case::Base`, `Micro::Service::Strict` → `Micro::Case::Strict`, etc.).
- **BREAKING:** The "pipeline" concept was renamed to "flow" throughout the public API (`Micro::Service::Pipeline` → `Micro::Case::Flow`).

---

## Pre-rename history (published as `u-service`)

## [u-service 1.0.0] - 2019-08-25
### Added
- `Micro::Service::Safe` and `Micro::Service::Strict::Safe`: service variants that rescue exceptions and return them as failure results.
- Safe pipelines that intercept exceptions raised inside services; the failing service instance is exposed on the resulting failure.
- `Micro::Service::Error` module gathering all gem-specific exceptions in one namespace.
- `to_proc` on services and pipelines, enabling use with iterators like `map(&MyService)`.
- `:exception` is returned as the result type whenever a failure value is an `Exception`.
- When a failure is invoked with a `Symbol`, that symbol is used as both the result type and value.

### Changed
- Any `ArgumentError` raised during service usage is now treated as a wrong-usage case and re-raised (even inside safe pipelines), instead of being swallowed as a failure.
- Pipeline reducers extracted into their own files; safe-pipeline reducer reworked for clarity.
- Default failure type for safe services improved so rescued exceptions produce a consistent `:exception` type.

## [u-service 0.14.0] - 2019-08-19
### Added
- Failure results now expose the service instance that produced them (accessible from the result), making it easier to identify which step in a pipeline failed.

### Changed
- Improved error messages when an invalid value is assigned as a result.

## [u-service 0.13.1] - 2019-08-19
### Changed
- Slimmed the published gem by excluding files unnecessary at runtime.

## [u-service 0.13.0] - 2019-08-19
### Added
- `require 'u-service/with_validation'` shortcut to enable the ActiveModel-validation mode.
- Default result types: `:ok` for success and `:error` for failure when none is provided.
- New `:validation_error` result type returned automatically when a validated service is invalid.

### Changed
- Result `type` is always coerced to a `Symbol`.
- The validation mode now modifies the base class on load rather than exposing separate `Validation` classes, simplifying the public API.

### Removed
- The internal `Validation` classes layer (superseded by the base-class extension above).

## [u-service 0.12.0] - 2019-08-14
### Changed
- Reduced object allocation while processing a pipeline, improving throughput.

## [u-service 0.11.0] - 2019-08-13
### Added
- Pipelines defined as classes are now validated at definition time, surfacing configuration mistakes earlier.
- Pipelines can be composed of other `Micro::Service` abstractions (services and pipelines used interchangeably as steps).

## [u-service 0.10.0] - 2019-08-10
### Added
- Composition operator for building a pipeline from services and/or other pipelines (e.g. `ServiceA >> ServiceB`).

## [u-service 0.9.0] - 2019-08-09
### Added
- `Micro::Service::Result::Success` and `Micro::Service::Result::Failure` subclasses, plus a `Result::Helpers` module — making it easier to pattern-match or branch on result kind.

## [u-service 0.8.0] - 2019-08-08
### Added
- Alternative class-level DSL for declaring pipelines inside a class (in addition to `Micro::Service::Pipeline[...]`).

## [u-service 0.7.0] - 2019-08-06
### Changed
- Optimized `Micro::Service::Pipeline` execution.

## [u-service 0.6.0] - 2019-08-06
### Added
- `Micro::Service::WithValidation`, integrating ActiveModel validations into services so invalid input short-circuits with a failure.
- CI matrix expanded to run against multiple ActiveModel versions.

## [u-service 0.5.0] - 2019-08-06
### Added
- Pipelines can be called with an existing `Result` as their starting input, enabling chaining across pipelines.

### Changed
- Renamed `Micro::Service::Strict::Base` to `Micro::Service::Strict`.

### Removed
- `Micro::Service::Strict::Base` (replaced by `Micro::Service::Strict`).

## [u-service 0.4.0] - 2019-08-05
### Added
- `Micro::Service::Result#type` is now validated (must be a non-blank symbol/string).

### Changed
- **BREAKING:** New positional/block API for `Success` and `Failure` helpers and factories: pass either a value directly, or a type as the argument and the value via block (e.g. `Failure(:invalid) { reason }`). The old `value:` / `type:` keyword combination no longer applies.

## [u-service 0.3.0] - 2019-08-05
### Added
- `Micro::Service::Pipeline` — compose multiple services into a single callable pipeline via `Micro::Service::Pipeline[ServiceA, ServiceB, ...]`.
- Argument validation for `Micro::Service::Pipeline[]` to catch bad pipeline definitions up front.

## [u-service 0.2.0] - 2019-08-05
### Added
- `Micro::Service::Strict::Base` — a strict variant that enforces that all declared attributes are provided.

## [u-service 0.1.0] - 2019-08-05
### Added
- Initial release of `u-service`.
- `Micro::Service::Base`: define services with attribute-based input and a `call!` method.
- `Micro::Service::Result` with `Success`/`Failure` factories and helper methods for returning typed results from services.
- Runtime dependency on `u-attributes` for service input declaration.

[Unreleased]: https://github.com/serradura/u-case/compare/v5.7.1...HEAD
[5.7.1]: https://github.com/serradura/u-case/compare/v5.7.0...v5.7.1
[5.7.0]: https://github.com/serradura/u-case/compare/v5.6.0...v5.7.0
[5.6.0]: https://github.com/serradura/u-case/compare/v5.5.0...v5.6.0
[5.5.0]: https://github.com/serradura/u-case/compare/v5.4.0...v5.5.0
[5.4.0]: https://github.com/serradura/u-case/compare/v5.3.1...v5.4.0
[5.3.1]: https://github.com/serradura/u-case/compare/v5.3.0...v5.3.1
[5.3.0]: https://github.com/serradura/u-case/compare/v5.2.1...v5.3.0
[5.2.1]: https://github.com/serradura/u-case/compare/v5.2.0...v5.2.1
[5.2.0]: https://github.com/serradura/u-case/compare/v5.1.0...v5.2.0
[5.1.0]: https://github.com/serradura/u-case/compare/v5.0.0...v5.1.0
[5.0.0]: https://github.com/serradura/u-case/compare/v4.5.2...v5.0.0
[4.5.2]: https://github.com/serradura/u-case/compare/v4.5.1...v4.5.2
[4.5.1]: https://github.com/serradura/u-case/compare/v4.5.0...v4.5.1
[4.5.0]: https://github.com/serradura/u-case/compare/v4.4.0...v4.5.0
[4.4.0]: https://github.com/serradura/u-case/compare/v4.3.0...v4.4.0
[4.3.0]: https://github.com/serradura/u-case/compare/v4.2.2...v4.3.0
[4.2.2]: https://github.com/serradura/u-case/compare/v4.2.1...v4.2.2
[4.2.1]: https://github.com/serradura/u-case/compare/v4.2.0...v4.2.1
[4.2.0]: https://github.com/serradura/u-case/compare/v4.1.1...v4.2.0
[4.1.1]: https://github.com/serradura/u-case/compare/v4.1.0...v4.1.1
[4.1.0]: https://github.com/serradura/u-case/compare/v4.0.0...v4.1.0
[4.0.0]: https://github.com/serradura/u-case/compare/v3.1.0...v4.0.0
[3.1.0]: https://github.com/serradura/u-case/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/serradura/u-case/compare/v3.0.0.rc9...v3.0.0
[3.0.0.rc9]: https://github.com/serradura/u-case/compare/v3.0.0.rc8...v3.0.0.rc9
[3.0.0.rc8]: https://github.com/serradura/u-case/compare/v3.0.0.rc7...v3.0.0.rc8
[3.0.0.rc7]: https://github.com/serradura/u-case/compare/v3.0.0.rc6...v3.0.0.rc7
[3.0.0.rc6]: https://github.com/serradura/u-case/compare/v3.0.0.rc5...v3.0.0.rc6
[3.0.0.rc5]: https://github.com/serradura/u-case/compare/v3.0.0.rc4...v3.0.0.rc5
[3.0.0.rc4]: https://github.com/serradura/u-case/compare/v3.0.0.rc3...v3.0.0.rc4
[3.0.0.rc3]: https://github.com/serradura/u-case/compare/v3.0.0.rc2...v3.0.0.rc3
[3.0.0.rc2]: https://github.com/serradura/u-case/compare/v3.0.0.rc1...v3.0.0.rc2
[3.0.0.rc1]: https://github.com/serradura/u-case/compare/v2.6.0...v3.0.0.rc1
[2.6.0]: https://github.com/serradura/u-case/compare/v2.5.0...v2.6.0
[2.5.0]: https://github.com/serradura/u-case/compare/v2.4.0...v2.5.0
[2.4.0]: https://github.com/serradura/u-case/compare/v2.3.1...v2.4.0
[2.3.1]: https://github.com/serradura/u-case/compare/v2.3.0...v2.3.1
[2.3.0]: https://github.com/serradura/u-case/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/serradura/u-case/compare/v2.1.1...v2.2.0
[2.1.1]: https://github.com/serradura/u-case/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/serradura/u-case/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/serradura/u-case/compare/v2.0.0.pre.4...v2.0.0
[2.0.0.pre.4]: https://github.com/serradura/u-case/compare/v2.0.0.pre.3...v2.0.0.pre.4
[2.0.0.pre.3]: https://github.com/serradura/u-case/compare/v2.0.0.pre.2...v2.0.0.pre.3
[2.0.0.pre.2]: https://github.com/serradura/u-case/compare/v2.0.0.pre...v2.0.0.pre.2
[2.0.0.pre]: https://github.com/serradura/u-case/compare/v1.1.0...v2.0.0.pre
[1.1.0]: https://github.com/serradura/u-case/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/serradura/u-case/compare/u-service-v1.0.0...v1.0.0
[u-service 1.0.0]: https://github.com/serradura/u-case/compare/u-service-v0.14.0...u-service-v1.0.0
[u-service 0.14.0]: https://github.com/serradura/u-case/compare/u-service-v0.13.1...u-service-v0.14.0
[u-service 0.13.1]: https://github.com/serradura/u-case/compare/u-service-v0.13.0...u-service-v0.13.1
[u-service 0.13.0]: https://github.com/serradura/u-case/compare/u-service-v0.12.0...u-service-v0.13.0
[u-service 0.12.0]: https://github.com/serradura/u-case/compare/u-service-v0.11.0...u-service-v0.12.0
[u-service 0.11.0]: https://github.com/serradura/u-case/compare/u-service-v0.10.0...u-service-v0.11.0
[u-service 0.10.0]: https://github.com/serradura/u-case/compare/u-service-v0.9.0...u-service-v0.10.0
[u-service 0.9.0]: https://github.com/serradura/u-case/compare/u-service-v0.8.0...u-service-v0.9.0
[u-service 0.8.0]: https://github.com/serradura/u-case/compare/u-service-v0.7.0...u-service-v0.8.0
[u-service 0.7.0]: https://github.com/serradura/u-case/compare/u-service-v0.6.0...u-service-v0.7.0
[u-service 0.6.0]: https://github.com/serradura/u-case/compare/u-service-v0.5.0...u-service-v0.6.0
[u-service 0.5.0]: https://github.com/serradura/u-case/compare/u-service-v0.4.0...u-service-v0.5.0
[u-service 0.4.0]: https://github.com/serradura/u-case/compare/u-service-v0.3.0...u-service-v0.4.0
[u-service 0.3.0]: https://github.com/serradura/u-case/compare/u-service-v0.2.0...u-service-v0.3.0
[u-service 0.2.0]: https://github.com/serradura/u-case/compare/u-service-v0.1.0...u-service-v0.2.0
[u-service 0.1.0]: https://github.com/serradura/u-case/releases/tag/u-service-v0.1.0
