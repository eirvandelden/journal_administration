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

- Permissions: approved by Etienne on 2026-10-16: five devDependencies in `package.json`, installed with yarn: `stylelint` 17.16, `stylelint-config-standard` 40.0, `eslint` 10.13, `@eslint/js` 10.0, `globals` 17.13. They exist because the dotfiles `stylelint` and `eslint` checks run `yarn stylelint` and `yarn eslint`, which `package.json` lacks. No other gems, system tools, destructive migrations or deploy files.
- The single file must not break teammates who lack the dotfiles.
- The dotfiles defaults must not run the same check twice next to a repository check (for example rubocop).
- Decided on 2026-10-16: dotfiles `parallel: true` is accepted for the repository pre-push checks; dotfiles `erb_lint` stays on; dotfiles `yamllint` excludes `config/locales/**`, because `i18n-tasks normalize` output must pass `i18n-normalized`.
- Dotfiles `stylelint` and `eslint` stay on and must pass, so the repository gets working configs for them.
- Repository checks keep their current behaviour: the union of both files, deduplicated. Where both run herb, the `.lefthook.yml` yarn version wins.

## In scope

- Merge `lefthook.yml` and `.lefthook.yml` into one file that builds on the dotfiles defaults.
- Delete `lefthook-local.yml`.
- Add the five approved devDependencies, a stylelint config and an eslint config, and fix what they flag in the existing CSS and JS so both checks pass.
- Exclude `config/locales/**` from `yamllint`.
- Fix the `erb_lint` offences in `app/views/layouts/application.html.erb`, so the kept check passes.
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
- `yarn stylelint` and `yarn eslint` run in the repository and pass on the existing CSS and JS.
- Committing a locale file normalized by `i18n-tasks normalize` passes both `yamllint` and `i18n-normalized`.
- Committing `app/views/layouts/application.html.erb` passes `erb_lint`.

## Open questions

None.
