# Intent: Add stylelint and eslint with working configs

Author: Etienne van Delden. Status: accepted. Type: chore. Delivery: autonomous.

2026-10-22: Etienne removed the lefthook switch from this change; the post-merge migration fix moves to his dotfiles.

## Problem

The dotfiles `stylelint` and `eslint` checks run `npx --no stylelint` and `npx --no eslint`.
This repository has neither package nor a config for them, so both checks cannot run here.
The two layouts also fail `erb_lint`.

## Proposed outcome

`stylelint` and `eslint` run in the repository with their own configs and pass on the existing CSS and JS.
Both layouts pass `erb_lint`.

## Constraints

- Permissions: approved by Etienne on 2026-10-16: five devDependencies in `package.json`, installed with npm (main moved from yarn to npm after this branch was cut; the approval stands, only the installer changed): `stylelint` 17.16, `stylelint-config-standard` 40.0, `eslint` 10.13, `@eslint/js` 10.0, `globals` 17.13. They exist because the dotfiles `stylelint` and `eslint` checks run `npx --no stylelint` and `npx --no eslint`, which `package.json` lacks. No other gems, system tools, destructive migrations or deploy files.
- The lefthook files stay exactly as on `main`.

## In scope

- Add the five approved devDependencies, a stylelint config and an eslint config.
- Fix what they flag in the existing CSS and JS so both checks pass.
- Fix the `erb_lint` offences in `app/views/layouts/application.html.erb` and `app/views/layouts/admin.html.erb`.

## Out of scope

- Any lefthook change, and any change to the dotfiles or the global shim.
- Running `stylelint` or `eslint` in CI.

## Acceptance criteria

- `npx --no stylelint` and `npx --no eslint` pass on the existing CSS and JS.
- `erb_lint` passes on both layouts.
- The lefthook files are unchanged against `main`.

## Open questions

None.
