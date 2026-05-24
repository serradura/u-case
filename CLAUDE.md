# CLAUDE.md

Repo notes for AI assistants working in `u-case`.

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
the `ENABLE_TRANSITIONS=true|false` axis.

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

## Other conventions

- `Gemfile.lock` is gitignored (standard for gems); don't commit it.
- The `Safe` family can be opted out via
  `Micro::Case.config.disable_safe_features = true` — keep that contract
  intact when touching `Micro::Case::Safe`, `Micro::Cases.safe_flow`, or
  `Result#on_exception`.
- The repo is mirrored under `solid-process/gems/`; CI mirrors the
  `solid-process` Appraisal layout.
