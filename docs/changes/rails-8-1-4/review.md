# Review: rails-8-1-4

## Round 1 — 2026-09-29T09:39Z — 5345b7f

Compliance: spec acceptance "Gemfile.lock resolves rails to 8.1.4, test suite and linters green" — proven by `Gemfile.lock` (all Rails-family gems 8.1.3.1 -> 8.1.4 with checksums, no other gem moved), boot check `Rails.version` = 8.1.4, `bin/rails test` 820 runs / 0 failures, rubocop, bundler-audit and brakeman clean. No tests weakened, skipped or deleted. Bugs and security passes: nothing found.

- [ ] Nit: `plan.md` has no `## Proof` section naming the checks that prove the change; the plan's step 3 lists them instead — `docs/changes/rails-8-1-4/plan.md:1` →
- [ ] Nit: intent says json "is moving to 3.x", but json is already 3.0.2 on main, so the stated problem does not match the branch state — `docs/changes/rails-8-1-4/intent.md:3` →
