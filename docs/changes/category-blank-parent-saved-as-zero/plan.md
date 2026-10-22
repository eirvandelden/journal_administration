# Plan: Blank parent category saved as 0

Status: accepted (2026-10-22).

## Design

In `category_params`, drop the `to_i` cast. Blank values become nil through `presence`. A migration sets parent_category_id to NULL where it is 0.

## Proof

- Controller test: creating a category with a blank parent stores nil and the new form lists it in the parent select.
- Migration: rows with 0 become NULL.
