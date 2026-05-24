# CLAUDE.md

Notes for AI assistants working in `u-case`.

## How to work in this repo

### 1. Think before coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity first

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes,
simplify.

### 3. Surgical changes

**Touch only what you must. Clean up only your own mess.**

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that _your_ changes orphaned. Don't
  remove pre-existing dead code unless asked.

The test: every changed line should trace directly to the user's request.

### 4. Goal-driven execution

**Define success criteria. Loop until verified.**

Turn vague tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step work, state a brief plan with a verification check per step.

---

## What this is

`u-case` is a Ruby gem (originally published as `u-service`) for representing
business use cases as small, composable objects with typed `Success`/`Failure`
results. Entry points live under `lib/micro/case` (`Micro::Case`,
`Micro::Case::Safe`, `Micro::Case::Result`, `Micro::Cases.flow`, etc.).
Behavior changes — especially anything that affects the public API or the
supported `ruby` / `activemodel` / `u-attributes` matrix — are highly visible
to downstream users.

## Running tests

```bash
bundle exec rake test                  # default suite, current bundle
bundle exec appraisal <name> rake test # one Rails appraisal (see Appraisals)
bundle exec rake matrix                # full local matrix for the active Ruby
```

`bin/setup` re-installs and refreshes appraisals. `bin/matrix` reinstalls then
runs `rake matrix`. CI runs the matrix across the full Ruby × Rails grid plus
the `ENABLE_TRANSITIONS=true|false` axis. Tests are the success criterion for
any behavior change — write or update a test first, then make it pass
(rule 4).

## CHANGELOG and READMEs are part of every change

Both files are user-facing — keep them in sync with the code:

- **`CHANGELOG.md`**: follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).
  Every user-visible change (new API, behavior change, breaking change, dep
  bump that shifts the supported matrix, security fix) gets a bullet under
  the appropriate section (`Added` / `Changed` / `Deprecated` / `Removed` /
  `Fixed` / `Security`). Pure README/CI/internal-refactor changes generally
  don't need an entry.
- **`README.md` and `README.pt-BR.md`**: the **Documentation** table and the
  **Compatibility** table at the top reference the latest released version
  and its dependency bounds. Update both files together — they are
  translations of each other and must stay in lockstep. If you change a
  documented API, update both READMEs in the same commit.

## Internal argument checks live in `Micro::Case::Check`

Every internal argument/contract check that runs inside the gem (type
guards, "is this a `Micro::Case`?", "is this a `Symbol`?", "are these
flow args valid?", etc.) lives in `lib/micro/case/check.rb`, split across
two modules with **identical method signatures**:

- `Micro::Case::Check::Enabled` — the default; raises the curated
  `Micro::Case::Error::*` exceptions.
- `Micro::Case::Check::Disabled` — no-ops (the matching method just
  `return`s; passthrough methods return their input unchanged).

The active one is referenced as `Micro::Case.check`, swapped by
`config.disable_runtime_checks = true/false` (see PR #145 / issue #45).

### When you add a new internal check, you must:

1. **Add the method to BOTH modules.** Keep the signature identical.
   The `Enabled` side does the real work; the `Disabled` side is a
   no-op (or passthrough for `hash!`-style coercions).
2. **Route the call site through `Micro::Case.check.<method>!(...)`.**
   Don't `raise ... unless ...` inline — that bypasses the toggle and
   leaks the check into the disabled-path performance budget.
3. **Cover both modes in a test.** Mirror the pattern in
   `test/micro/case/disable_runtime_checks_test.rb`: one test that the
   `Enabled` side raises, one that the `Disabled` side does not.
4. **Avoid extra allocation on the call site.** If the curated
   exception needs dynamic params (a class name, a context string),
   pass the raw strings/values into the check method and construct the
   exception inside `Enabled` (only on the raise path). Don't build the
   exception before calling — that defeats the perf rationale of the
   `Disabled` side.

This is the only place where new gem-internal checks belong. Inline
`raise … unless …` inside the runtime call path is a regression of
this design — flag it during review and move the check into
`Micro::Case::Check`.

## Bumping the version

1. Edit `lib/micro/case/version.rb` — change `Micro::Case::VERSION`. Follow
   [SemVer](https://semver.org/): patch for fixes, minor for additive
   user-visible changes, major for breaking changes.
2. Add a new top entry in `CHANGELOG.md` (`## [X.Y.Z] - YYYY-MM-DD`) and a
   matching compare link at the bottom (`[X.Y.Z]: …/compare/vPREV...vX.Y.Z`).
3. Update both READMEs:
   - **Documentation** table → bump the `v5.x` (or current major) row's
     version label.
   - **Compatibility** table → if dependency bounds changed, add a new row;
     otherwise bump the existing row's version label.
4. If `Gemfile`/`u-case.gemspec` dependency bounds moved, double-check the
   Compatibility table and `Appraisals` reflect the new bounds.

Don't tag, push, or `gem release` — humans do that.
