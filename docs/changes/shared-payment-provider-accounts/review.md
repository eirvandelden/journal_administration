## Round 14 — 2026-10-15 12:25 UTC — 734d735

Reviewed `git diff origin/main...HEAD` after fetching origin, plus the working tree (clean at review start). No root `REVIEW.md` or `REVIEW.local.md` exists; used the default Bugs, Security and Compliance passes.

No Important or Nit findings.

The current branch deliberately removed its intent, plan and earlier review rounds in commit `734d735` ("Remove change artifacts for shared-payment-provider-accounts"). The compliance reference below is explicitly historical: the accepted intent and plan read from `734d735^`. Those files are not present in the current tree, and this report does not restore or change their acceptance status. Historical reviews were consulted to identify accepted design tradeoffs, including suffix stripping and category equality; the code was reviewed independently.

### Validation

- RuboCop: 309 files inspected, no offenses.
- Herb: 90 files checked, no offenses.
- Brakeman: no security warnings (one existing ignored warning).
- Bundler audit: no vulnerabilities found.
- Full Rails suite: 955 runs, 2534 assertions, 0 failures, 0 errors, 0 skips (64.84 seconds).

The two initial sandboxed test launches were stopped; the full suite was rerun with normal filesystem access and this worktree's `bin/` first on `PATH`.

### Compliance against historical accepted intent

| Acceptance criterion | Proving test in this diff |
| --- | --- |
| Shared Adyen, `Naam: Kruidvat` books on Kruidvat | `test/jobs/importing/ing/import_job_test.rb`: "a payment through a shared provider books on the merchant's existing account" |
| Unknown `Kirovanni/Foodticket` creates an external account and books on it | `test/jobs/importing/ing/import_job_test.rb`: "a payment through a shared provider to an unknown merchant creates that merchant" |
| Shared Mollie drops the `via` suffix | `test/jobs/importing/ing/import_job_test.rb`: "a via suffix is dropped from the merchant name" |
| Shared Buckaroo drops the `by` suffix | `test/jobs/importing/ing/import_job_test.rb`: "a by suffix is dropped from the merchant name" |
| `Naam: Adyen` stays on Adyen | `test/jobs/importing/ing/import_job_test.rb`: "a payment naming the provider itself stays on the provider" |
| Unmarked AON keeps existing import behavior | `test/jobs/importing/ing/import_job_test.rb`: "a payment to an account that is not a shared provider books on that account" |
| Newly marked provider's transactions stay until a separate move | `test/integration/merchant_reassignments_test.rb`: "marking a provider leaves its transactions until they are moved" |
| Provider default category becomes merchant default | `test/integration/merchant_reassignments_test.rb`: "a moved transaction with the provider's default category gets the merchant's default" |
| Hand-picked categories and splits survive | `test/integration/merchant_reassignments_test.rb`: "a moved transaction keeps a category chosen by hand" and "a moved split transaction keeps its splits" |
| Second move changes nothing | `test/integration/merchant_reassignments_test.rb`: "moving a second time moves nothing" |
| Unmarking affects new imports and preserves previous moves | `test/integration/payment_providers_test.rb`: "unmarking a provider books new imports on it and leaves moved transactions" |
| Assistant marks and moves with the same behavior | `test/integration/assistant_test.rb`: "the assistant marks a shared provider and moves its transactions to their merchants" |

All 52 tests named in the historical plan's `## Proof` section exist. No existing test was weakened, skipped or deleted: every test diff is additive. Authentication, external-account validation, CSRF protection, MCP destructive annotations and rollback behavior were reviewed; no new security issue found.

### Delivery tooling

The skill's configured `~/.claude/skills/deliver/scripts/deliver` path is absent. The equivalent source executable exists at `/Users/etienne.vandelden/Developer/dotfiles/claude/.claude/skills/deliver/scripts/deliver`; its read-only `--check` is used after committing this report. A successful check does not recreate the removed intent and plan needed by the delivery write path.
