# Plan: Manage people and groups without code changes

From `intent.md` (2026-10-10). Status: accepted.

## Design decisions

- Add `Person`, `Group`, and `GroupMembership` as ordinary resources. A person has a name and a household flag. A group has a name and selected person members. Nested groups remain unsupported.
- Keep `accounts.owner` and `appropriations.recipient` unchanged as immutable legacy fields. Add nullable `person_id` and `group_id` to accounts, and nullable `person_id` to appropriations. New behavior reads the associations. The old values remain an audit-compatible record of imported history.
- An account is household-owned when its linked person is a household member or its linked group has a household member. This replaces `Account::FAMILY_OWNERS` and the owner enum as the transaction-classification authority. An account with no linked household owner remains external, even if it is associated with a non-household person.
- The account form offers every person and group as a mutually exclusive owner choice. It clears both references for an external account. Model validation and a database check constraint require zero or one owner reference. It refuses any ownership change that would reclassify an account with transactions.
- An appropriation belongs to a person. Its recipient text is set from that person on creation only, and is never rewritten. Replace legacy recipient-text uniqueness with a case-insensitive `purpose`, `person_id`, and `budget_year` index and validation. A person rename therefore changes displayed names without changing historical recipient text, amounts, or charges.
- The migration creates one case-insensitive person for every existing individual account owner and appropriation recipient. It marks legacy individual owners as household members and recipient-only people as outside the household. It creates `Samen`, adds Etienne and Michelle, links legacy `samen` accounts to it, and links named accounts and appropriations to their matching people. The migration preserves legacy owner and recipient column values and all financial records.
- People and groups use restrictive associations. A used person cannot be deleted when an account, appropriation, or group membership references it. A used group cannot be deleted when an account references it. Removing a group membership destroys only that join record. A person or membership update cannot remove the final household ownership needed by an account with transactions.
- Assistant tools accept and report person names through the linked person. The set tool resolves a person by case-insensitive name and refuses unknown or group recipients. Listing uses the current person name. Account search reports its current linked owner name and household status.

## Integration points

- `Account.own`, `Account.external`, and `Account#external?` retain their names but use managed household ownership. `Accountable`, `Transaction`, and `Current.account` derive classification from that behavior. This preserves debit, credit, and transfer classification after owner names change.
- `Resolvable`, account alias validation, account absorption, account index, transaction filters, and assistant account search retain their existing scope semantics through the managed household-owned scope. Preload people and groups with memberships where account listings render owner details.
- `Current.account` selects the first household-owned account with a group owner, then falls back to the first account. It never identifies `Samen` by a renameable group name.
- Account and appropriation HTML and JSON representations must expose the current managed owner or recipient without replacing legacy database fields.
- The MCP server must keep its existing authorization and transport behavior while its account and appropriation tools adopt managed records.
- Add translations in English, Dutch, and Italian, then normalize locale files.

## Files that change

- `db/migrate/<timestamp>_create_people_groups_and_memberships.rb` — create people, groups, memberships, foreign keys, uniqueness indexes, nullable account/appropriation association columns, the zero-or-one-account-owner constraint, and the new appropriation person uniqueness index; remove the legacy recipient-text uniqueness index.
- `db/data/<later-timestamp>_migrate_people_groups_and_legacy_owners.rb` — use migration-local records and explicit legacy enum integer mapping to backfill canonical case-insensitive people, household status, `Samen`, memberships, and account/appropriation links without validation or legacy-value changes.
- `app/models/person.rb` — validate case-insensitive unique names, expose household membership, and restrict deletion when referenced.
- `app/models/group.rb` and `app/models/group_membership.rb` — own group membership selection, validate unique memberships, determine household ownership, and restrict referenced-group deletion.
- `app/models/account.rb`, `app/models/concerns/accountable.rb`, `app/models/concerns/resolvable.rb`, and `app/models/current.rb` — replace enum-based household checks with managed associations, preserve read-only legacy owner access, and reject ownership changes that invalidate historical classifications.
- `app/models/appropriation.rb` — require a managed recipient for new records, set legacy recipient text only when creating, preserve totals and charging behavior, and restrict recipient deletion.
- `app/controllers/people_controller.rb`, `app/controllers/groups_controller.rb`, `app/controllers/accounts_controller.rb`, and `app/controllers/appropriations_controller.rb` — add CRUD resources and permit managed person, group, and recipient parameters; stop permitting legacy account owner updates.
- `config/routes.rb`, `app/views/people/*`, `app/views/groups/*`, and `app/views/layouts/application.html.erb` — add resource routes, management pages, member selection, and navigation.
- `app/views/accounts/*`, `app/views/appropriations/*`, `app/helpers/appropriations_helper.rb`, and account/appropriation JSON templates — use current managed names and selection controls while retaining the legacy data in serialized output where it already exists.
- `app/tools/assistant/find_accounts.rb`, `app/tools/assistant/set_appropriation.rb`, and `app/tools/assistant/list_appropriations.rb` — select and report managed people and current account owners.
- `config/locales/en.yml`, `config/locales/nl.yml`, and `config/locales/it.yml` — add labels, validation messages, navigation, and CRUD feedback.
- `test/fixtures/people.yml`, `test/fixtures/groups.yml`, `test/fixtures/group_memberships.yml`, and updated account/appropriation fixtures — establish linked household and outside-person records.
- `test/models/person_test.rb`, `test/models/group_test.rb`, `test/models/group_membership_test.rb`, `test/models/account_test.rb`, `test/models/appropriation_test.rb`, `test/models/transaction_test.rb`, and `test/models/concerns/resolvable_test.rb` — cover associations, constraints, deletion rules, naming, imports, and transaction classification.
- `test/data/migrate_people_groups_and_legacy_owners_test.rb` — exercise the data migration against legacy owner and recipient records, including case variants.
- `test/integration/people_test.rb`, `test/integration/groups_test.rb`, `test/integration/accounts_index_test.rb`, `test/integration/accounts_show_test.rb`, `test/integration/appropriations_test.rb`, `test/integration/account_authorization_test.rb`, `test/integration/assistant_test.rb`, and `test/integration/main_navigation_test.rb` — prove the user and MCP flows.

## Order of work

1. Write the data migration acceptance test. Remove managed fixture links first, then prove legacy individual owners, `samen`, recipient case variants, unchanged raw legacy values, and untouched financial data. Run it and observe failure because the records and migration do not exist.
2. Write model tests for people, groups, memberships, account ownership, appropriation recipients, deletion restrictions, and transaction classification. Run the affected tests and observe failure.
3. Add the schema migration, then a later data migration. Create the records, case-insensitive indexes, foreign keys, restrictive associations, zero-or-one-owner constraint, and recipient-person uniqueness rule. Use explicit legacy integer values and direct migration writes. Run the migration test twice until it proves idempotent backfill preserves legacy columns, amounts, charges, classifications, and links.
4. Implement the rich model behavior and replace enum/constant ownership checks in transactions, imports, `Current.account`, alias validation, and account absorption. Run the focused model tests until family classification remains correct after a person rename and ownership-status reductions are refused when history depends on them.
5. Write failing integration tests for person and group CRUD, group member removal, account owner selection, external accounts, and deletion refusals. Add the controllers, routes, templates, navigation, translations, and fixture data. Run those tests until green.
6. Write failing appropriation integration and assistant tests for an outside recipient, rename propagation, managed recipient selection, and current assistant answers. Update appropriation behavior, forms, views, helpers, JSON, and tools. Run focused tests until green.
7. Run the complete Rails test suite, RuboCop, Herb lint, Brakeman, Bundler Audit, and locale normalization. Re-read the diff and run the independent reviews before the pull request.

## Risks

- A partial migration can cause a legacy account to become external. The data migration must be idempotent, mark legacy owners as household people, link every non-null legacy owner, and prove scopes, imports, debit, credit, and transfer types before and after migration.
- Reusing a historical recipient spelling can collide with the obsolete legacy uniqueness key. Replace that index with person-based uniqueness before accepting new appropriations.
- Case-insensitive matching must use a durable database uniqueness rule and canonical lookup, not Ruby-only comparison, so migrations and concurrent UI or MCP writes cannot create duplicate people.
- Do not introduce companies, brands, nested groups, group appropriation recipients, multiple households, charge-rule changes, or changes to PR #337.

## Proof

- A user adds a household member in the app and selects that person as an account owner without a deployment. → `test/integration/people_test.rb` `test "a user creates a household person and assigns that person to an account"`
- A user creates or edits `Samen`, sees its members, and assigns it to a joint bank account. → `test/integration/groups_test.rb` `test "a user edits Samen members and assigns Samen to an account"`
- A user records a grandparent outside the household and selects that person for an appropriation. → `test/integration/appropriations_test.rb` `test "an appropriation selects an outside person"`
- Renaming a person changes the name on all their appropriations and assistant responses; amounts and charges stay unchanged. → `test/integration/appropriations_test.rb` `test "renaming a recipient updates displayed appropriations without changing charges"`; `test/integration/assistant_test.rb` `test "the assistant reports a renamed appropriation recipient"`
- Existing individual owners remain linked to the corresponding people. Existing `samen` accounts remain household-owned through `Samen`, whose initial members are Etienne and Michelle. → `test/data/migrate_people_groups_and_legacy_owners_test.rb` `test "migrates named owners and Samen without changing legacy owners"`
- Existing free-text recipients remain represented after migration. Case variants do not create duplicate people. → `test/data/migrate_people_groups_and_legacy_owners_test.rb` `test "migrates case-variant recipients to one person"`
- Account ownership still determines debit, credit and transfer behavior correctly. Renaming an owner does not change financial history. → `test/data/migrate_people_groups_and_legacy_owners_test.rb` `test "preserves household scopes and transaction types after migration"`; `test/models/transaction_test.rb` `test "managed household owners determine transaction type after a rename"`; `test/models/concerns/resolvable_test.rb` `test "resolves a migrated household account from an import description"`
- Referenced people and groups cannot be deleted. Removing an unused group or a group member does not delete any person. → `test/models/person_test.rb` `test "refuses to destroy account, appropriation, and membership references"`; `test/models/group_test.rb` `test "destroying an unused group keeps its people"`; `test/models/group_test.rb` `test "refuses to destroy a group that owns an account"`; `test/models/group_membership_test.rb` `test "removing a membership keeps the person"`
- The delivery ends at a tested, linted and independently reviewed PR. Etienne decides whether to merge it. → check: `bin/rails test`; `bundle exec rubocop`; `npx @herb-tools/linter app/views/`; `bundle exec brakeman --no-pager -q`; `bundle exec bundler-audit check`; `bundle exec i18n-tasks normalize`; independent Claude and Codex reviews; open PR targeting `main` after PR #337 merged.

Per changed file, the unit tests expected, named as behaviour:

- `app/models/person.rb`: `Person#household?`, `Person#cannot_be_destroyed_when_referenced`, `Person#refuses_to_drop_household_status_from_a_used_owner`, `Person#normalizes_case_insensitive_names`.
- `app/models/group.rb`: `Group#household?`, `Group#cannot_be_destroyed_when_owned_by_account`, `Group#destroying_an_unused_group_keeps_people`.
- `app/models/group_membership.rb`: `GroupMembership#refuses_duplicate_person`, `GroupMembership#refuses_to_remove_the_last_household_member_from_a_used_owner`, `GroupMembership#removing_a_membership_keeps_the_person`.
- `app/models/account.rb`: `Account#household_owned?`, `Account#refuses_both_person_and_group`, `Account#refuses_reclassification_with_transactions`, `Account#keeps_legacy_owner`.
- `app/models/appropriation.rb`: `Appropriation#sets_legacy_recipient_on_create_only`, `Appropriation#rename_preserves_amount_and_charges`, `Appropriation#refuses_duplicate_purpose_person_year`.
- `app/models/concerns/accountable.rb`: `Accountable#uses_managed_household_ownership`.
- `app/models/current.rb`: `Current.account#returns_the_Samen_group_account`.
- `db/data/<later-timestamp>_migrate_people_groups_and_legacy_owners.rb`: `MigratePeopleGroupsAndLegacyOwners#up_migrates_legacy_owners_and_recipients_idempotently`.
- `app/tools/assistant/find_accounts.rb`: `Assistant::FindAccounts.call_reports_current_managed_owner`.
- `app/tools/assistant/set_appropriation.rb`: `Assistant::SetAppropriation.call_selects_case_insensitive_person_and_refuses_unknown_recipient`.
- `app/tools/assistant/list_appropriations.rb`: `Assistant::ListAppropriations.call_uses_current_person_name`.

Test setup: fixtures contain Etienne and Michelle as household people, `Samen` with both memberships, an outside grandparent, linked existing accounts and appropriations, and a charged appropriation. Migration tests first clear account and appropriation links, then delete memberships, groups, and people before calling `up` twice.

---
Domain skills applied: Rails architecture, object-oriented design, Ruby style, Rails testing, Rails guides, 37signals style.

## Critique

### Round 1 (Claude Opus)

- Migrated legacy owners lacked household status. → fixed (The migration creates legacy individual owners as household people and proves the resulting scopes.)
- Person rename rewrote immutable legacy recipient text. → fixed (Recipient text is creation-only and person-based uniqueness replaces the legacy recipient index.)
- Ownership changes could invalidate existing transactions. → fixed (Account, person, and membership validation refuse reclassification when transactions depend on household ownership.)
- Classification and import behavior lacked migration proof. → fixed (The migration and resolvable tests prove scopes, transaction types, and imported family-account resolution.)
- Migration fixtures already contained managed links. → fixed (Migration tests clear links and managed records before two backfill runs.)
- The migration depended on changing application models. → fixed (A later data migration uses explicit legacy integers and direct migration writes.)
- Existing ownership scope callers were omitted. → fixed (The integration list names scope callers and preserves their public behavior with managed ownership.)
- Current account lookup depended on the renameable Samen name. → fixed (Current account selects a group-owned household account by association.)
- Deletion and assistant proofs targeted incomplete behavior. → fixed (The plan splits deletion tests by reference and exercises assistant tools through their public integration boundary.)
