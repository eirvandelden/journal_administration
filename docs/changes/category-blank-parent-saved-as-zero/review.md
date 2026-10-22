## Round 1 — 2026-10-22 19:26 UTC — 0b5bf5c

Reviewed `git diff origin/main...HEAD` after fetching origin, plus the working tree (clean). No root `REVIEW.md` or `REVIEW.local.md` exists; used the default Bugs, Security, Compliance and Design passes.

- [ ] Important: `category_params` assigns `parent_category_id` even when the request does not send it, so a partial update such as a JSON `PATCH {category: {name: "x"}}` clears the category's parent (verified: the permitted hash becomes `{"name" => "x", "parent_category_id" => nil}`). Rails already casts `""` to `nil` for the integer column (`Category.new(parent_category_id: "").parent_category_id` is `nil`), so the `tap` is redundant; without it, blank stays nil and an absent key stays untouched — `app/controllers/categories_controller.rb:82` → fixed (Keep a category's parent when an update omits it)
- [ ] Nit: "updating a category with a blank parent clears the parent" uses `categories(:groceries)`, which has no parent in the fixtures, so it never shows a set parent being cleared. A child fixture such as `supermarket` proves the behaviour the name claims — `test/integration/categories_create_test.rb:22` → fixed (Keep a category's parent when an update omits it)
- [ ] Nit: `categories_create_test.rb` also holds the update test; a name such as `categories_parent_test.rb` matches its content — `test/integration/categories_create_test.rb:3` → fixed (Keep a category's parent when an update omits it)

### Validation

- Narrow run of the two new test files: 5 runs, 6 assertions, 0 failures.
- Full Rails suite: 1315 runs, 3903 assertions, 0 failures, 0 errors, 0 skips.
- RuboCop on the changed Ruby files: no offenses.
- Brakeman: no warnings. Bundler audit: no vulnerabilities.

### Security

No finding. Strong parameters stay in place; the migration runs fixed SQL with no interpolation.

### Compliance

| Acceptance criterion | Proving test |
| --- | --- |
| Creating "Kinderen" without a parent makes it appear in the parent dropdown of the new category form | `test/integration/categories_create_test.rb`: "a category created without a parent is offered as a parent" |

| Proof line in plan.md | Test |
| --- | --- |
| Creating with a blank parent stores nil and the new form lists it | `test/integration/categories_create_test.rb`: "creating a category without a parent stores no parent" and "a category created without a parent is offered as a parent" |
| Migration: rows with 0 become NULL | `test/migrations/reset_zero_parent_category_ids_test.rb`: "up turns a parent of 0 into no parent", "up keeps a real parent" |

No existing test was weakened, skipped or deleted.

### Design

The design matches plan.md. No glossary `Avoid:` word appears. No Law of Demeter or N+1 finding. The codebase uses no inline RBS and plan.md has no `### Signatures`, so no signature finding. `db/schema.rb` changes only the version line.

Note: `origin/main` moved ahead of this branch (merge of #378); a rebase belongs to `deliver`/`sync`, not this review.

## Round 2 — 2026-10-22 19:38 UTC — fc924b9

Reviewed `git diff origin/main...HEAD` after fetching origin, plus the working tree (clean apart from this report). No root `REVIEW.md` or `REVIEW.local.md` exists; used the default Bugs, Security, Compliance and Design passes. The branch now sits on current `origin/main` (c3e653d).

No findings. All three round 1 findings hold as fixed: `category_params` permits without a `tap`, so a blank parent casts to nil and an absent key leaves the parent untouched; the update tests use the `supermarket` child fixture; the file is `categories_parent_test.rb`.

### Validation

- Narrow run of the two new test files: 6 runs, 7 assertions, 0 failures.
- Full Rails suite: 1316 runs, 3904 assertions, 0 failures, 0 errors, 0 skips.
- RuboCop on the changed Ruby files: no offenses.
- Brakeman: no warnings. Bundler audit: no vulnerabilities.

### Bugs

No finding. No other code writes `parent_category_id` (no MCP tool, seed or lib writer). The migration also unblocks `BudgetCategory`'s `must_be_parent` check, which treated 0 as a parent.

### Security

No finding. Strong parameters stay in place; the migration runs fixed SQL with no interpolation.

### Compliance

| Acceptance criterion | Proving test |
| --- | --- |
| Creating "Kinderen" without a parent makes it appear in the parent dropdown of the new category form | `test/integration/categories_parent_test.rb`: "a category created without a parent is offered as a parent" |

| Proof line in plan.md | Test |
| --- | --- |
| Creating with a blank parent stores nil and the new form lists it | `test/integration/categories_parent_test.rb`: "creating a category without a parent stores no parent" and "a category created without a parent is offered as a parent" |
| Migration: rows with 0 become NULL | `test/migrations/reset_zero_parent_category_ids_test.rb`: "up turns a parent of 0 into no parent", "up keeps a real parent" |

No existing test was weakened, skipped or deleted.

### Design

The design matches plan.md. No glossary `Avoid:` word appears. No Law of Demeter or N+1 finding. The codebase uses no inline RBS and plan.md has no `### Signatures`, so no signature finding. `db/schema.rb` changes only the version line.

Note: the local branch was rebased onto `origin/main`, so `origin/category-blank-parent-saved-as-zero` (0b5bf5c) has diverged from it.
