# Record which brand made a chattel

A handoff plan. Read it whole before touching anything; it is the only context you get.

## Why

A chattel is a valuable thing the household owns — a laptop, a phone, a washing machine — kept for
warranty and insurance. Today a chattel records a `name`, a `kind` ("electronics"), a `model_number`
("XPS-15") and a `serial_number`, but nothing says who made it. So the brand ends up inside the name
("Old Phone" is really a Pixel 7), or nowhere at all. You cannot ask "what Philips things do we own"
or "is anything of this brand still under warranty".

Groceries already solved the same problem the simple way: a product carries its brand as a plain
string, and the form offers the brands already in use so the same brand is not typed two ways. This
brings chattels in line with that.

## Decide with the owner before starting

- **Whether existing names should be split up.** Some chattel names contain the brand already.
  Pulling "Pixel-7" out of a name is guesswork on real data, so this plan does not do it. Confirm
  that leaving old records alone is acceptable.
- **Whether the brand field should be required.** This plan leaves it optional, like a product's.

## What already exists

`Chattel` lives in `app/models/chattel.rb`. It includes `Searchable` with
`searchable_on :name, :kind, :model_number, :serial_number, :notes`, and `PdfAttachmentValidatable`
for its warranty document. `ChattelsController` groups the index by warranty status (warrantied,
out of warranty, unknown, left possession) and permits its fields in `chattel_params`. The form is
`app/views/chattels/_form.html.erb`, a list of `<div class="field">` blocks; the table is
`app/views/chattels/_table.html.erb`.

On the grocery side, `Product` carries `brand` as a string and offers `Product.brands_in_use` — the
distinct brands already recorded — which its form renders as a `datalist`. Copy that shape.

## Steps

Test first, always. Minitest with fixtures; no FactoryBot.

### Step 1 — a chattel records its brand

Tests, in `test/controllers/chattels_controller_test.rb` (where the existing chattel request tests
live):

| Test name | Asserts |
| --- | --- |
| `creating a chattel records the brand that made it` | posting a chattel with a brand stores it |
| `the chattels page shows each brand` | the index renders the brand of a fixture chattel |
| `a chattel is found by its brand` | searching for the brand returns the chattel |

The third one needs `:brand` adding to the `searchable_on` list — the model's own test file
(`test/models/chattel_test.rb`) is the better home for it if the search tests live there; follow
whatever the file already does.

Then:

- A migration adding `brand` as a string to `chattels`. Nothing needs an index yet: nobody looks a
  chattel up by brand alone, and the table is small.
- `:brand` in `chattel_params`, and in `searchable_on`.
- `Chattel.brands_in_use`, mirroring `Product.brands_in_use`:
  `where.not(brand: [nil, ""]).distinct.order(:brand).pluck(:brand)`.
- A brand field in `_form.html.erb` above `kind`, as a text field with `list:` pointing at a
  `datalist` of `Chattel.brands_in_use`, matching how the product form does it. Build the list in the
  controller, not the view.
- A brand column in `_table.html.erb`, and the brand on the chattel's own page.
- A brand for one or two fixtures in `test/fixtures/chattels.yml`, so the index test has something to
  find. Leave at least one without a brand: that is the normal state of old records.

Locale keys in **all three** locales (`en`, `nl`, `it`) — `test/i18n_test.rb` fails otherwise, and it
also requires the files to be normalised:

```
activerecord.attributes.chattel.brand
chattels.index.brand      # or whatever the table's heading keys look like
```

Run `bundle exec i18n-tasks normalize` after editing locale files.

Commit: `feat(chattels): record which brand made a chattel`.

### Step 2 — decide about the duplicate query

`Chattel.brands_in_use` and `Product.brands_in_use` will be the same three lines on two models. Two
copies is not yet duplication worth removing — the rule of three says wait. Leave both, and note it
for whenever a third model needs brands. Do **not** build a `Branded` concern for two callers, and do
**not** introduce a brand table: brand stays a string until a rename or a per-brand page actually
hurts.

No commit of its own; this step is a decision, not code.

## Files this touches

- `db/migrate/*_add_brand_to_chattels.rb`, `db/schema.rb`
- `app/models/chattel.rb`
- `app/controllers/chattels_controller.rb`
- `app/views/chattels/_form.html.erb`, `_table.html.erb`, `show.html.erb`
- `config/locales/en.yml`, `nl.yml`, `it.yml`
- `test/fixtures/chattels.yml`, `test/controllers/chattels_controller_test.rb`,
  `test/models/chattel_test.rb`

## How to verify

```
bin/rails test
bundle exec rubocop
bundle exec herb lint app/views/chattels/
```

All green, including `test/i18n_test.rb`. The project runs on the Ruby in `.ruby-version`; in a shell
where `rv` does not resolve that per directory, put it in front of every command or Bundler refuses
to boot:

```
PATH="$HOME/.local/share/rv/rubies/ruby-4.0.6/bin:$PATH" bin/rails test
```

The repository inherits a shared rubocop configuration from the `rubocop-eirvandelden` gem: one field
per validation, private helpers below `private`, predicate assertions in tests, and a blank line
before each assertion. Run `bundle install` first if the gem is missing.

Work in a worktree under `.worktrees/`, never in the main checkout, and never commit to `main`.

## Out of scope

- Merging `Chattel#kind` with the groceries' `ProductType`. They are the same idea at different
  grains ("electronics" versus "naturel chips") and unifying them is a real refactor that only pays
  off if you want reporting across groceries and durables together. Not now.
- A brand table, shared or otherwise.
- Guessing brands out of existing chattel names.
- Anything in the grocery feature: it is being reviewed on its own branch.
