# Intent: Bundler-based git hooks work from a worktree

Author: Etienne van Delden de la Haije. Status: accepted. Type: chore. Delivery: autonomous. Codex review: no.

## Problem

A commit or push from a `.worktrees/*` checkout runs the lefthook hooks, and every Bundler-based hook fails with exit status 7 before it checks anything. This covers pre-commit rubocop and pre-push rubocop, brakeman, bundler_audit and tests. Git exports `GIT_DIR` to hooks. Bundler then cannot find the git-sourced gems (`appkit`, `mvpa-css`) and reports "Your bundle is locked to … from https://github.com/eirvandelden/… can no longer be found". The push is refused, so the only way through today is to skip the hooks.

Reproduce from a worktree: `GIT_DIR=$(git rev-parse --git-dir) bundle exec ruby -e 'puts :ok'` fails; the same command without `GIT_DIR` prints `ok`.

## Proposed outcome

From a worktree, the Bundler-based hooks run their real checks and pass or fail on the code alone. A push from a worktree no longer needs any hook skipped.

## Affected users and systems

- Etienne and the agents that commit and push from `.worktrees/*` checkouts.
- `lefthook.yml`: the pre-commit and pre-push commands that run through Bundler.

## Constraints

- The checks keep running with the same strictness. Changing how `lefthook.yml` starts a command is the fix itself, not a linter config edit to dodge a check (playbook rules 2 and §7a).
- A commit or push from the main checkout keeps working as it does today.
- No new dependency.
- Permissions: none needed. No gems, system tools, destructive migrations or deploy files.
- The `navigation-hubs` branch rebases onto this fix afterwards.

## In scope

- The Bundler-based commands in `lefthook.yml`, pre-commit and pre-push.

## Out of scope

- The herb hooks (`npx`), which do not run through Bundler.
- The binstub gotcha: Rails binstubs resolving `APP_ROOT` to the main checkout.
- The missing `node_modules` gotcha in new worktrees.
- CI, which runs no git hooks.

## Acceptance criteria

- A push from a worktree runs rubocop, brakeman, bundler_audit and tests, and each reports its real result instead of exit status 7.
- A commit of a staged Ruby file from a worktree runs rubocop on that file and reports its real result.
- A rubocop offence in a worktree still blocks the commit: the hook is not silenced.
- A push from the main checkout still runs every hook and passes as before.

## Decisions

- Fix `lefthook.yml` on its own branch, then rebase `navigation-hubs` on it — keeps the hook fix out of the feature branch (decided with the navigation-hubs coordinator).
- Deliver autonomously — the fix is small and well understood.
- Skip the Codex review — the change is a few lines of config.

## Open questions

None.
