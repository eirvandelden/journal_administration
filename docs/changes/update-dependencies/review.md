# Review: update-dependencies

## Round 1 — 2026-10-11T06:55:23Z — 847f305

- [ ] Important: The plan was not followed for the herb finding. herb 0.11's `html-no-nested-forms` reads `turbo_frame_tag` as a `<form>`. I reproduced this on origin/main's view: it flags `form_with` at line 3 as "cannot be nested inside another `<form>`". `turbo_frame_tag` renders `<turbo-frame>`, not a form, so the finding is a false positive. The plan's "Fix, never silence" decision says: "If a finding looks like a false positive, stop and ask Etienne." The branch works around the finding with a literal tag instead. The implementation notes call the finding a nested form and do not record a decision from Etienne. The markup itself is correct. turbo-rails 2.0.23 renders `tag.turbo_frame(id: "budget_form", target: "_top")`, which gives the same id and target. The suggestion button's `data-turbo-frame="budget_form"` still targets the frame, and the form stays inside it. Record Etienne's decision, or report the false positive upstream. — `app/views/budgets/_form.html.erb:2` →
- [ ] Nit: No test pins the budget form frame. `test/integration/budgets_test.rb` asserts neither `turbo-frame#budget_form` nor `target="_top"`, and no other test checks them. The frame is now hand-written markup, so a later edit can drop the id or the target and the suite stays green. Other frames have such checks, for example `assert_select "turbo-frame#transaction_splits"`. — `test/integration/budgets_test.rb:103` →
- [ ] Nit: Some lockfile changes are not explained. The implementation notes name `selenium-webdriver`, `lefthook` and `date` as late releases. The branch also moves `rubocop` 1.91.0 → 1.92.0 (in 072a0cb), and `uri` 1.1.1 → 1.1.2 and `prettyprint` 0.2.0 → 0.2.1 (in 20fa41a). None of the three is in the intent's 27-gem list. The subject of 20fa41a names only `solid_cable`. The bumps are in scope: they are transitive unlocks to the newest release. Only the record is incomplete. — `Gemfile.lock:379` →
- [ ] Nit: The plan says Bundler 4 drops the patchlevel from `RUBY VERSION`, but the lockfile still says `ruby 4.0.7p0`. The guard test's `[/\d+\.\d+\.\d+/]` copes with both forms, so nothing breaks. Only the plan's prediction is wrong. — `Gemfile.lock:755` →

Checked and clean:

- Migration: matches solid_cable 4.1.0's `remove_channel_index` template line for line. I ran it on a scratch SQLite database loaded from origin/main's `db/cable_schema.rb`. `up` drops only `index_solid_cable_messages_on_channel`. `down` restores it under the same name. Running either direction twice is a no-op. Production's cable database records schema version 1 and has no other cable migration, so `db:prepare` in `bin/start-app` runs this migration on the next deploy. The `db/cable_schema.rb` diff loses only the index line and changes the version.
- Guard test: a missing `ARG RUBY_VERSION` line or a missing `RUBY VERSION` section gives `nil`, so the test fails loudly. The test checks `.ruby-version` only indirectly, through the Gemfile's `ruby file:`, as the plan intends.
- Scope: each commit touches only the files its subject names. There are no stray config, whitespace or `.github/` changes. The `bundler (4.0.22)` CHECKSUMS line and the dropped `rexml` (selenium-webdriver 4.51 no longer depends on it) are explained.
- Under Ruby 4.0.7: `bin/rails test` gives 893 runs, 0 failures, and prints no warning or deprecation. rubocop, herb (0 failing), Brakeman, bundler-audit and `i18n-tasks normalize` all pass, with a clean `git status`.

Compliance (acceptance criteria → proof):

- `bundle outdated` lists only `marcel` → I ran the command: only `marcel 1.2.1 → 2.1.0` is listed.
- `yarn outdated` lists nothing → I ran the command: it lists nothing.
- Ruby 4.0.7 in all three places → `test/configuration_test.rb` "the production image and the lockfile pin the Ruby the tests run on" (passes under 4.0.7).
- `BUNDLED WITH 4.0.22` → `Gemfile.lock:758`, and `bundle -v` prints 4.0.22.
- Actions point at their latest release → `actions/checkout@v7.0.1` is the latest. `actions/setup-node@v7` resolves to v7.1.0 (2026-10-08), the latest.
- `bin/rails test` and the system tests pass → the unit and integration tests are green. The system tests are left to CI, as Etienne accepted.
- Linters pass → I ran them, all green.
- No new deprecation warnings → the test output contains none.
- `/mcp` still lists transactions → `test/integration/assistant_test.rb:318` "the assistant finds the transactions that still need a category".
- Every test named in `## Proof` exists. No existing test was weakened, skipped or deleted.
