# Phase 02 — Classify products

Read `00-context.md` first.

## Why

A product arriving from an invoice knows only its name and pack size. Its brand and product type are
decided by a person. Until that happens the product has no accounting category, so its share of the
money cannot be split and lands on the payment's own category instead, and no comparison across brands
is possible. Nothing in the app can set them today, and nothing points out which products are waiting.

## Decide with the owner before starting

- The first real product types and the accounting category each is booked to. Two exist only as test
  fixtures. Seeding real ones is the owner's call and not this phase's work.
- Whether a product type may be deleted while products still point at it. The steps below block that,
  since deleting one would silently unclassify its products.

## Step 1 — Product types as a resource

### Tests first

`test/integration/product_types_test.rb`:

| Test name | Asserts |
| --- | --- |
| `the product types page lists each type with the category it is booked to` | "Naturel chips" and "Groceries" appear in the same row |
| `a product type can be created for a category` | posting name and `category_id` adds one and redirects to the list |
| `a product type without a category is refused` | posting without `category_id` re-renders the form and shows the error |
| `two product types cannot share a name` | posting "Naturel chips" again is refused rather than raising |

The last one matters: there is a unique index on `LOWER(name)`, so without a model validation the
duplicate reaches the database and raises instead of showing a message. Add
`validates :name, uniqueness: { case_sensitive: false }` to `ProductType` as part of this step — its
first test is right here.

### Then

- `resources :product_types, except: %i[destroy show]` unless the owner asked for deletion.
- `ProductTypesController` following `CategoriesController`: `before_action :set_product_type, only:
  %i[edit update]`, strong parameters permitting `%i[name category_id]`, redirect with a `t(...)` notice
  on success, re-render the form on failure.
- `index`: `ProductType.includes(:category).order(:name)`.
- `app/views/product_types/index.html.erb` — table of name and category, each row linking to its edit
  page.
- `app/views/product_types/_form.html.erb` — name text field, category select from
  `Category.order(:name)`. Include the form error summary the other forms use.
- Locale keys `product_types.index.*`, `product_types.form.*`, `product_types.create.success`,
  `product_types.update.success`, `activerecord.models.product_type`, `main_nav.product_types`, in three
  locales.
- Navigation entry beside categories.

Commit: `feat(groceries): manage the types products belong to`.

## Step 2 — Product list and classification

### Tests first

`test/integration/products_test.rb`:

| Test name | Asserts |
| --- | --- |
| `the products page lists what we buy with brand and type` | a row holds "AH Naturel Ribbelchips", "AH" and "Naturel chips" |
| `the products page marks what still needs classifying` | the row for `products(:andrelon_shampoo)` carries `I18n.t("products.index.unclassified", locale: :en)` |
| `classifying a product records its brand and type` | patching brand "Andrélon" and the shampoo type leaves `product.reload.unclassified?` false |
| `the brand field offers the brands already in use` | the edit page contains a `datalist` `option` with "Lay's" |
| `a product cannot lose its name` | patching a blank name is refused and shows the error |

### Then

- `resources :products, only: %i[index show edit update]`. The show page gets its real content in phase
  03; here it need only display name, brand, type and pack size, so the list has somewhere to link to.
- `ProductsController`, strong parameters permitting `%i[name brand product_type_id pack_amount
  pack_unit]`.
- `index`: `Product.includes(:product_type).order(:name)`, paginated as in phase 01 if the list grows
  past a page.
- `app/views/products/_form.html.erb`: name, a brand text field with `list:` pointing at a `datalist`
  built from

```ruby
Product.where.not(brand: [nil, ""]).distinct.order(:brand).pluck(:brand)
```

  a product type select including a blank option, and pack amount plus pack unit (the unit select from
  `Product.pack_units.keys`). Put that brand query in the controller or a model scope, not in the view.
- The index marks unclassified rows using the existing `Product#unclassified?`; do not re-derive the rule
  in the view.
- Locale keys `products.index.*`, `products.show.*`, `products.form.*`, `products.update.success`,
  `activerecord.models.product`, `activerecord.attributes.product.*` for the form labels,
  `main_nav.products`, in three locales. Pack unit names need translating too — `products.pack_units.gram`
  and so on for all five.

Commit: `feat(groceries): set a product's brand and type by hand`.

## Step 3 — Unclassified products on the todo page

### Tests first

`test/models/todo_test.rb`:

| Test name | Asserts |
| --- | --- |
| `a product still needing a brand or type is something to do` | `Todo.new.items` includes an item whose record is `products(:andrelon_shampoo)` and whose kind is `:product` |
| `a classified product is nothing to do` | no item's record is `products(:ah_ribbelchips)` |

And in the existing todo page test (`test/integration/todos_test.rb` or the controller test, whichever
exists): `the todo page links a product still needing a type to its form` — the page contains
`edit_product_path(products(:andrelon_shampoo))`.

### Then

`Todo` today builds `Item = Struct.new(:kind, :date, :record)` from two sources and sorts by date,
newest first. Add a third private method beside `transaction_items` and `account_items`:

```ruby
def product_items
  Product.unclassified.order(created_at: :desc)
         .map { |product| Item.new(:product, product.created_at, product) }
end
```

and include it in `items`.

The view needs care: `app/views/todos/index.html.erb` currently decides the kind label and the actions
with a two-way ternary (`item.kind == :transaction ? ... : ...`). Three kinds do not fit a ternary —
replace it with a `case item.kind` for both the label and the actions block. `todo_description(item)`
in `app/helpers/todos_helper.rb` already falls back to `item.record.to_s` for anything that is not a
transaction, which gives the product's name once `Product#to_s` returns it; add that method if it is
missing rather than special-casing the helper.

Locale keys: `todos.index.product`, `todos.index.classify`, in three locales.

### Watch out

- `TodosController` paginates a plain array with its own `Page` struct and `PER_PAGE = 20`. Adding a
  third source changes the counts but needs no pagination change.
- The todo page is the one place that will show a flood right after the first real import: every product
  on the first invoice is new and unclassified. That is correct behaviour, not a bug to hide.

Commit: `feat(groceries): put products still needing a type on the todo list`.

## Files this phase touches

- `config/routes.rb`
- `app/controllers/product_types_controller.rb`, `app/controllers/products_controller.rb`
- `app/models/product_type.rb` (uniqueness validation), `app/models/product.rb` (`#to_s` if absent),
  `app/models/todo.rb`
- `app/views/product_types/*`, `app/views/products/*`, `app/views/todos/index.html.erb`,
  `app/views/layouts/application.html.erb`
- `config/locales/en.yml`, `nl.yml`, `it.yml`
- `test/integration/product_types_test.rb`, `test/integration/products_test.rb`, todo tests

## Out of scope

- Guessing a brand or type from the product name. A person decides; that decision is the whole point.
- Merging duplicate products, and any alias table.
- Seeding real product types.
- Bulk classification screens. Wait until the todo list proves them necessary.
