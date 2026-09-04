# Phase 05 — Finish the branch

Read `00-context.md` first. Do this once phases 01 to 03 are done, and phase 04 as far as it can go.

## Steps

1. **Sync.** Fetch and rebase `ai/grocery-basket` onto `main` — rebase, never merge main into the
   branch. Resolve each conflicted file on its own merits. Push with `--force-with-lease`, never plain
   `--force`.
2. **Re-verify.** `bin/rails test` fully green apart from the two known chattels failures described in
   `00-context.md`. If those two are gone, better — the `Gemfile.lock` situation was resolved elsewhere.
3. **Lint everything touched.** `bundle exec rubocop` and `bundle exec herb lint` on every file in the
   diff. No disable comments.
4. **Security.** `bundle exec brakeman` and `bundle exec bundler-audit check --update`, both clean.
5. **Read the whole diff.** Every hunk must be required by this feature. Revert anything unrelated:
   whitespace, quote style, renamed test strings, lint configuration, `.github/` files. Do not commit
   machine-local files (`Gemfile.lock` bumps you did not make, `bin/` binstubs, editor configuration,
   `.env`, `db/seeds_private.rb`).
6. **Pull request.** Target `origin`, the personal fork. Use the repository's pull request template if
   one exists under `.github/`. Describe it in domain language: what you can now see and answer that you
   could not before. List what is deliberately absent — a brand table, a parent product type, an alias
   table, hand-entry forms — so a reviewer does not read them as oversights. Note the phase 04 steps
   that were left undone and why.

## Do not

- Post or reply to anything on GitHub as the owner without being asked for that exact message. Opening
  the pull request is not permission to comment further.
- Merge the pull request yourself.
- Bundle the chattels brand change, or any other orthogonal improvement, into this branch.
