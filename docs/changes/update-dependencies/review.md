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

## Round 2 — 2026-10-12T15:23:43Z — de2e72d

Scope: `git diff fab7ab4..HEAD`.

- [ ] Nit: The search results `case` has no `else` branch. The old loop rendered `searches/_result_<type>` for any key, so a new key in `Search#compute_results` without a partial raised a missing-template error. Now a new key renders its `<h3>` heading with no items and no error. The `case` also repeats the five keys that `Search#compute_results` defines, so the two lists can drift apart. All five current keys have a `when` branch, so the page renders the same today. — `app/views/searches/index.html.erb:8` →
- [ ] Nit: The test names in `record_forms_test.rb` claim more than the tests prove. "the new account form creates an account" and the others only check the form's `action`, `method`, `_method`, `enctype` and the field name prefix. No test submits a form. The checks are the right guard for the `form_with` rewrite. Only the names overstate it, for example "the new account form posts account fields to the accounts path" would match. — `test/integration/record_forms_test.rb:8` →
- [ ] Nit: No test guards the "show" link on the transaction edit page. `transactions_index_test.rb` proves that `_table` keeps the `/credit/:id` and `/debit/:id` links. If someone changes `polymorphic_path(@transaction)` on the edit page to `transaction_path`, the link changes to `/transactions/:id` and the suite stays green. — `app/views/transactions/edit.html.erb:5` →

Checked and clean:

- Dockerfile: `awk '/BUNDLED WITH/ { getline; print $1 }'` reads `4.0.22` from the indented line below `BUNDLED WITH`. The install runs after the lockfile `COPY` and before `bundle lock`, so the whole `bundle` step uses 4.0.22. The gem goes into `GEM_HOME=/usr/local/bundle`, which is `BUNDLE_PATH`, so the final stage's `COPY --from=build "${BUNDLE_PATH}"` carries it. The `rm -rf "${BUNDLE_PATH}"/ruby/*/cache` step does not delete `/usr/local/bundle/cache/bundler-4.0.22.gem`, which is a few hundred KB. I did not rebuild the image. The amd64 `bundle -v` evidence is the implementer's record in the plan's amendment notes.
- `.herb.yml` `framework: actionview`: herb checks 90 files, finds 0 offenses and prints no framework notice. 9400978 changes only `.herb.yml`. The 40 offenses were info and hint level, so every commit kept the linter green.
- Qualified partial paths: every new path names a partial in the same controller's view folder, for example `admin/users/_form` and `products/_price_chart`. The lookup result does not change, and every local is passed as before.
- Route helpers: `Account`, `Category`, `Chattel` and `Appropriation` have no STI subclasses, so `account_path(account)` and similar helpers give the same URL as `link_to record`. Transactions keep `polymorphic_path`, and `routes.rb:35-37` maps it to `/credit`, `/debit` and `/transfer`. The new `transactions_index_test.rb` test fails if `_table` switches to `transaction_path`.
- Explicit collection partials: `users/_user`, `account_aliases/_account_alias` and the five `searches/_result_*` partials declare one strict local each. The `as:` names match those locals. An empty collection renders nothing in both forms. The new accounts, users and searches tests fail if a partial stops rendering or gets the wrong local. Search now has a test for each of its five result types.
- `label` → `pct_label`: only a rename, and the HTML stays the same. The new test pins `60%` inside the status span.
- `form_for` → `form_with model:`: `load_defaults 8.0` makes `form_with` generate field ids and no `data-remote`, so labels and field ids stay the same. The param key comes from `model_name.param_key`, which keeps `credit[...]` for an STI credit. The URL comes from `polymorphic_path`, and a persisted record gets `_method=patch`. `form_with` still sets `multipart` when the builder sees a `file_field`, and the chattel and credit tests prove that. One change in the HTML: the `<form>` element loses `form_for`'s `id`/`class` (`new_account`, `edit_chattel_1`). No CSS, JS, Turbo Stream, controller or system test refers to those ids or classes.
- Scope: each commit changes only the views of the rule it names, plus that rule's tests. There are no stray config, whitespace or `.github/` changes.
- Under Ruby 4.0.7: `bin/rails test` gives 908 runs, 0 failures, 0 errors, 0 skips, and prints no warnings. rubocop, herb, Brakeman, bundler-audit and `i18n-tasks normalize` pass, and `git status` stays clean. The system tests are left to CI, as Etienne chose.
- The round 1 findings are addressed in the branch: the decision is recorded in the implementation notes, a7c9ec4 adds the frame test, and the notes explain the bumps and the patchlevel. Their `→` slots are still empty.

Compliance (amendment acceptance criteria → proof):

- In the built `linux/amd64` image, `bundle -v` prints 4.0.22 → the `docker run` output recorded in plan.md "Amendment notes". I did not run it again.
- herb lint passes with `framework: actionview` and prints no framework notice → I ran `npx @herb-tools/linter app/views/`: 0 offenses, no notice.
- The amendment's `## Proof` names no new unit test. The tests the amendment notes list all exist: transaction links by kind (`transactions_index_test.rb`), search results by type (`searches_test.rb`), account aliases (`accounts_show_test.rb`), the users index (`users_index_test.rb`), the budget percentage label (`balance_partial_test.rb`) and the six record forms (`record_forms_test.rb`).
- No existing test was weakened, skipped or deleted.

## Round 3 — 2026-10-13T12:43:54Z — 5e177f2

Scope: `git diff eb0c0af..HEAD` (one commit, 5e177f2, tests only). No uncommitted changes.

- [ ] Nit: The new test "the edit page of a credit links back to the credit's own page" checks a navigation link, not a form, but it sits in `record_forms_test.rb`. The file's other tests all check what a form submits. `transactions_show_test.rb` and `transactions_index_test.rb` already hold the transaction page and link checks, so a reader looks there first. — `test/integration/record_forms_test.rb:65` →

Checked and clean:

- The seven renamed tests now say what they assert: the form's action, method and field prefix, plus the file field where one exists. The assertions did not change. This closes round 2's naming nit.
- The new link test discriminates. On the credit edit page, the only link to `/credit/:id` is the "show" link in the header `<nav>`. `_form`, `_whole_payment_charge`, `transaction_splits/_frame` and the `transaction_links` partials link only to nested paths. If `polymorphic_path(@transaction)` becomes `transaction_path`, the link changes to `/transactions/:id` and the test fails. This closes round 2's edit-link nit.
- Round 2's search `case` nit (`app/views/searches/index.html.erb:8`, no `else` branch) has no change on the branch. Its `→` slot is still empty.
- Under Ruby 4.0.7: `bin/rails test` gives 909 runs, 0 failures, 0 errors, 0 skips. rubocop, herb, Brakeman, bundler-audit and `i18n-tasks normalize` pass, and `git status` stays clean.

Compliance:

- The commit adds one test and renames seven. No existing test was weakened, skipped or deleted.
- The intent and plan acceptance criteria are unchanged since round 2, and their proofs still pass.
