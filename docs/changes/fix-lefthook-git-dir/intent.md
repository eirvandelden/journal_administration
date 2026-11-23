# Intent: Bundler-based git hooks work from a worktree

Author: Etienne van Delden de la Haije. Status: accepted. Type: chore. Delivery: autonomous. Codex review: no.

## Problem

A commit or push from a `.worktrees/*` checkout runs the lefthook hooks, and every Bundler-based hook fails with exit status 7 before it checks anything. This covers pre-commit rubocop and pre-push rubocop, brakeman, bundler_audit and tests. Git exports `GIT_DIR` to hooks. Bundler then cannot find the git-sourced gems (`appkit`, `mvpa-css`) and reports "Your bundle is locked to … from https://github.com/eirvandelden/… can no longer be found". The push is refused, so the only way through today is to skip the hooks.

Reproduce from a worktree: `GIT_DIR=$(git rev-parse --git-dir) bundle exec ruby -e 'puts :ok'` fails; the same command without `GIT_DIR` prints `ok`.

## Proposed outcome

From a worktree, the Bundler-based hooks run their real checks and pass or fail on the code alone. A push from a worktree no longer needs any hook skipped.

## Affected users and systems

- Etienne and the agents that commit and push from `.worktrees/*` checkouts.
- `lefthook.yml`: the pre-commit and pre-push commands. It becomes the dotfiles `remotes:` stanza plus the local jobs the shared config lacks.
- `.lefthook.yml`: deleted. Lefthook never loaded it.
- `AGENTS.md`: the hooks line.

## Constraints

- The checks keep running with the same strictness. Changing how `lefthook.yml` starts a command is the fix itself, not a linter config edit to dodge a check (playbook rules 2 and §7a).
- A commit or push from the main checkout keeps working as it does today.
- No new dependency. The shared `erb_lint` job is skipped, because erb_lint is not installed here.
- Permissions: none needed. No gems, system tools, destructive migrations or deploy files.
- The `navigation-hubs` branch rebases onto this fix afterwards.

## In scope

- `lefthook.yml` follows dotfiles ADR 0001: shared config under `remotes:`, and the shared job wins where jobs overlap.
- Local jobs kept: `herb-lint`, `herb-lint-full`, `herb-analyze`, `i18n-normalized`. The Bundler jobs start with `unset GIT_DIR`.
- Delete `.lefthook.yml`, update `AGENTS.md`, and run `lefthook install` once as a local step.

## Out of scope

- The `bin/rails` binstub failing with `GIT_DIR` set.
- Upgrading msgpack (1.8.7 or later) and puma (8.0.3 or later), which bundler-audit flags. This is a separate branch (rule 25).
- The binstub gotcha: Rails binstubs resolving `APP_ROOT` to the main checkout.
- The missing `node_modules` gotcha in new worktrees.
- CI, which runs no git hooks.

## Acceptance criteria

- A push from a worktree runs the shared rubocop, brakeman, bundle-audit and minitest jobs, and each reports its real result instead of exit status 7. The shared brakeman and bundle-audit jobs run only on pushes that touch `Gemfile`; the shared minitest and rubocop jobs cover pushed files. Full runs stay in CI.
- A commit of a staged Ruby file from a worktree runs rubocop on that file and reports its real result.
- A rubocop offence in a worktree still blocks the commit: the hook is not silenced.
- A push from the main checkout still runs every hook and passes as before. Full proof is possible only after merge, because the main checkout reads its own `lefthook.yml` until then.

## Decisions

- Fix `lefthook.yml` on its own branch, then rebase `navigation-hubs` on it — keeps the hook fix out of the feature branch (decided with the navigation-hubs coordinator).
- Deliver autonomously — the fix is small and well understood.
- Skip the Codex review — the change is config only.
- Follow dotfiles ADR 0001 with a `remotes:` stanza (decided by Etienne, 2026-11-23, during planning) — widens the scope beyond the Bundler commands.

## Open questions

- Does the msgpack and puma upgrade land before or after this branch? Until it lands, any push that touches `Gemfile` is refused.
