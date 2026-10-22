# Intent: Blank parent category saved as 0

Author: Etienne van Delden de la Haije. Status: accepted (2026-10-22). Type: bugfix. Delivery: step-by-step.

## Problem

A new category with no parent is saved with parent_category_id 0. It then does not appear in the parent category dropdown.

## Proposed outcome

A category without a parent has no parent_category_id. It appears in the dropdown and in the root group on the index page.

## Affected users and systems

Anyone who creates or edits categories. Existing rows with parent_category_id 0.

## Constraints

The migration only touches rows with parent_category_id 0 and deletes no data.

## In scope

Fix the blank parameter handling. Reset existing 0 values to NULL.

## Out of scope

Other category behaviour.

## Acceptance criteria

- Creating "Kinderen" without a parent makes "Kinderen" appear in the parent dropdown of the new category form.
