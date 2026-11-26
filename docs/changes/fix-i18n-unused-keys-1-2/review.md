# Review: fix-i18n-unused-keys-1-2

## Round 1 — 2026-11-26T10:38:29Z — 550ed442

No `REVIEW.md` or `REVIEW.local.md` exists; the reviewer's default Bugs, Security, Compliance and Design passes apply.

Checks run: `i18n-tasks health` green ("Every translation is in use"), `i18n-tasks unused` exit 0, `bin/rails test test/i18n_test.rb` 7/7 green, full `bin/rails test` 1698 runs, 0 failures. Scratch dead-key check lists exactly `menu.unused_example` in en, it and nl. Scratch missing-key check lists `en search.shortcut_hint`.

Compliance:

- `i18n-tasks health` green → verified by command.
- `test/i18n_test.rb` passes unchanged → `test_no_unused_keys` green; `test/i18n_test.rb` not in the diff.
- `i18n-tasks normalize` leaves locales unchanged → `test_files_are_normalized` green; health reports "All data is normalized".
- A dead key is still reported → verified by the scratch check.
- Missing-key detection stays strict → verified by the scratch check.
- `git diff main --stat` lists only `config/i18n-tasks.yml` and the change folder → fails, see the Important finding.

Bugs, Security, Design: the code change is one YAML setting with a comment. No Ruby, no signatures, no queries. Nothing found.

- [ ] Important: The branch is not based on main alone. It carries three commits that origin/main does not hold: `d7674928` (docs for `fix-bundler-audit-advisories`), `46670b81` (puma 8.0.3 → 8.1.2) and `ac1966e2` (net-ssh 7.3.6 → 7.3.10). The plan says "Branches off main", lists the gem bumps as out of scope, and requires `git diff main --stat` to show only `config/i18n-tasks.yml` and this change folder; today it also shows `Gemfile.lock` and `docs/changes/fix-bundler-audit-advisories/`. The copies also differ from `origin/fix-bundler-audit-advisories` (that branch bumps puma from 8.0.2), so they conflict when that branch rebases on this fix, and `deliver` would merge the other change's folder into main. Drop the three commits so the branch holds only `0bb8f4f2` and `550ed442` on top of origin/main. — `Gemfile.lock:275` → dismissed: stacking is intentional. Etienne chose it on 2026-11-26, because each fix's pre-push audit and tests only pass with the other present. The PR targets `fix-bundler-audit-advisories` (playbook rule 20, stacked branches), and against that base the diff holds only `config/i18n-tasks.yml` and this change folder. The audit branch is rebased onto the same main, so the copies no longer differ.
