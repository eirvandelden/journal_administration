# Intent: One lefthook config that builds on the dotfiles defaults

Author: Etienne van Delden. Status: accepted. Type: bugfix. Delivery: autonomous.

## Problem

After `git pull` in this repository, `rails db:migrate` does not run when `db/schema.rb` changes.
The global `post-merge` shim only loads the dotfiles lefthook config when the repository has no lefthook config of its own.
This repository has three: `lefthook.yml`, `.lefthook.yml` and a comment-only `lefthook-local.yml`.
So the dotfiles `post-merge` and `post-rewrite` hooks, with their migrations step, never run here.
Two overlapping repo files also make it unclear which checks apply.

## Proposed outcome

The repository has exactly one lefthook config file.
The effective config is the dotfiles defaults plus the repository's own checks.
A pull that changes `db/schema.rb` runs the migrations, for a merge pull and a rebase pull.

## Affected users and systems

- Etienne, on this machine, with the dotfiles stowed.
- Other contributors: they get the repository checks and nothing breaks without the dotfiles.
- Git hooks `pre-commit`, `pre-push`, `post-merge`, `post-rewrite`, and the global shim in `~/.config/git/hooks`.

## Constraints

- Permissions: none needed. No gems, system tools, destructive migrations or deploy files are touched.
- The single file must not break teammates who lack the dotfiles.
- The dotfiles defaults must not run the same check twice next to a repository check (for example rubocop).
- Repository checks keep their current behaviour: the union of both files, deduplicated. Where both run herb, the `.lefthook.yml` yarn version wins.

## In scope

- Merge `lefthook.yml` and `.lefthook.yml` into one file that builds on the dotfiles defaults.
- Delete `lefthook-local.yml`.
- Verify the migrations step fires after a pull that changes `db/schema.rb`.

## Out of scope

- Changes to the dotfiles repository or the global shim.
- Changing which checks the repository runs, beyond removing duplicates.
- Fixing the `remotes:` mechanism for other repositories.

## Acceptance criteria

- The repository holds one lefthook config file, and `lefthook-local.yml` is gone.
- `lefthook dump` shows `pre-commit`, `pre-push`, `post-merge` and `post-rewrite`.
- Pulling a commit that changes `db/schema.rb` runs the migrations step.
- Pulling with a rebase runs the migrations step too.
- Pulling a commit that leaves `db/schema.rb` alone does not run the migrations.
- Every check from the old files still runs on commit or push, and none runs twice.

## Open questions

None.
