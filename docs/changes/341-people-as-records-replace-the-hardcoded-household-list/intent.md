# Intent: Manage people and groups without code changes

Author: Etienne van Delden. Status: accepted (2026-10-10). Type: feature. Delivery: autonomous.

## Problem

The household members and account owners are hardcoded. Adding or renaming a person needs a code change and deployment. The shared `samen` owner does not record which people own that account.

Appropriation recipients are free text. Renaming a recipient does not update every appropriation that refers to that person.

## Proposed outcome

Manage people, their household membership, groups and group members in the app. A bank account can belong to a person or a group. `Samen` initially contains Etienne and Michelle and represents their joint account ownership.

Appropriations refer to managed people. Renaming a person updates their displayed name throughout appropriations and assistant responses. Existing ownership and recipient data migrate without losing financial history.

## Affected users and systems

Household users of Journal Administration, its accounts, appropriations and assistant tools.

## Constraints

- Deliver issue #341 through autonomous delivery. Etienne accepts this intent and retains the final merge decision.
- Build on `appropriations`, the branch for open PR #337. Target that branch until it merges.
- Preserve existing account ownership, transaction classifications, appropriation amounts and charges during migration.
- Preserve legacy owner values and recipient text. Removing their columns requires separate approval.
- Keep existing security, authorization, translations, testing and review requirements.
- Do not add dependencies, change system tools or deployment configuration, deploy, or merge pull requests.

## In scope

- Create and edit people, including people outside the household. Mark whether a person belongs to the household.
- Create and edit groups. Select their members from the managed people.
- Select either a person or a group as an account owner. Preserve external accounts without a household owner.
- Convert existing named owners into people and `samen` into the `Samen` group containing Etienne and Michelle.
- Convert existing appropriation recipients into people by name, without duplicating case variants of the same name.
- Select people as appropriation recipients. Update assistant tools to select and report managed people and account owners.
- Prevent deletion of people used by accounts, appropriations or groups. Prevent deletion of groups used by accounts.

## Out of scope

Companies, brands, nested groups, groups as appropriation recipients, and multiple-household support. Changing budget calculations, appropriation charging rules or existing PR #337 also stays outside this change.

## Acceptance criteria

- A user adds a household member in the app and selects that person as an account owner without a deployment.
- A user creates or edits `Samen`, sees its members, and assigns it to a joint bank account.
- A user records a grandparent outside the household and selects that person for an appropriation.
- Renaming a person changes the name on all their appropriations and assistant responses; amounts and charges stay unchanged.
- Existing individual owners remain linked to the corresponding people. Existing `samen` accounts remain household-owned through `Samen`, whose initial members are Etienne and Michelle.
- Existing free-text recipients remain represented after migration. Case variants do not create duplicate people.
- Account ownership still determines debit, credit and transfer behavior correctly. Renaming an owner does not change financial history.
- Referenced people and groups cannot be deleted. Removing an unused group or a group member does not delete any person.
- The delivery ends at a tested, linted and independently reviewed PR. Etienne decides whether to merge it.

## Open questions

None.
