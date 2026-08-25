# Phase 03 — The price history

Read `00-context.md` first.

## Why

This is what the feature is for. Two questions:

- What did *this* product cost through the year, and when was it on bonus? A pack shrinking from 300 g to
  250 g at the same shelf price is a price rise, and only the price per kilo shows it.
- How much of *this kind of thing* do we buy, and how do the brands compare? "Naturel chips" bought as
  Albert Heijn's own bag and as Lay's should stand side by side.

## Decide with the owner before starting

- Which period the product type page totals by: calendar month or four-week blocks.
- Whether the product page shows every purchase ever or the last twelve months by default.

The steps below assume calendar months and every purchase; change them if the answer differs.

## Step 1 — Purchase history on the product page

### Tests first

`test/models/product_test.rb`:

| Test name | Asserts |
| --- | --- |
| `a product knows every time we bought it, newest first` | `products(:lays_ribbelchips).purchases` returns its line from `receipts(:albert_heijn_friday)`; with a second, older receipt added in the test, the newer comes first |
| `a product we never bought has no purchases` | `products(:andrelon_shampoo).purchases` is empty |

`test/integration/products_test.rb`:

| Test name | Asserts |
| --- | --- |
| `a product page shows what each purchase cost` | the page holds the invoice date, `number_to_currency(2.19)` as shelf price, `number_to_currency(0.70)` as bonus, `number_to_currency(1.49)` as paid, and `number_to_currency(4.97)` as price per kilo |
| `a product page says when we never bought it` | for the shampoo, `I18n.t("products.show.never_bought", locale: :en)` appears and no table is rendered |

The 4.97 is the fixture arithmetic: 1.49 paid for 300 g is 4.9666… per kilo, rounded to two decimals by
`ReceiptLine#paid_price_per_unit`.

### Then

On `Product`:

```ruby
def purchases
  receipt_lines.joins(:receipt).includes(:receipt).order("receipts.issued_on DESC")
end
```

which needs `has_many :receipt_lines` on `Product` — it does not exist yet. Add it without `dependent:`,
since a product must not be deletable while purchases refer to it.

`app/views/products/show.html.erb`: brand, product type, current pack size, then a table of purchases —
date, pack size, shelf price, bonus, paid, price per unit. Reuse the unit labels already in
`receipts.basket.units.*`; do not add a second set. Link each row's date to its receipt.

Locale keys `products.show.purchases`, `products.show.never_bought`, and the column headings — reuse
`receipts.basket.shelf_price`, `.bonus`, `.paid`, `.per_unit` rather than duplicating them.

Commit: `feat(groceries): show what a product cost each time we bought it`.

## Step 2 — The price chart

### Tests first

`test/integration/products_test.rb`:

| Test name | Asserts |
| --- | --- |
| `a product bought more than once is charted` | with two purchases in the test, `assert_select "svg polyline", count: 2` and both series carry two points each |
| `a product bought once shows the table without a chart` | `assert_select "svg", count: 0` |
| `the chart says what it shows` | the `svg` has a `title` element, and the two series are named in text beside it |

Assert on how many points reach the chart and on the labels, not on path coordinate strings. The geometry
will be adjusted by eye afterwards and the tests must survive that.

### Then

`app/views/products/_price_chart.html.erb`, with `<%# locals: (purchases:) %>`. Hand-written inline SVG:
no dependency, no JavaScript, no canvas.

- Two `polyline`s over one x axis of purchase dates: shelf price per unit and paid price per unit. The
  gap between them is the bonus history.
- Compute the point coordinates in a small helper (`app/helpers/products_helper.rb`), not in the template
  — the template stays markup. Scale the y axis from zero to the highest shelf price per unit so a bonus
  never looks like a loss.
- `role="img"` and a `<title>` inside the `svg`, plus a short sentence naming the two series, so the page
  is not silent to a screen reader. A table of the same numbers already sits above it, which is the real
  accessible fallback.
- Colours from the existing custom properties, never hex literals: `var(--color-fg)` for axes,
  `var(--color-primary)` and `var(--color-success)` for the two series. Those come from mvpa.css and
  already flip with the light and dark themes.
- Skip the chart entirely below two purchases; a single point is not a trend.

Commit: `feat(groceries): chart a product's price per unit over time`.

## Step 3 — Product type comparison

### Tests first

`test/models/product_type_test.rb`:

| Test name | Asserts |
| --- | --- |
| `a product type knows the products we buy under it` | naturel chips returns both the Albert Heijn and the Lay's bag |
| `a product type knows what each product last cost per unit` | both come back with 4.97 |
| `a product type totals what we spent per month` | the month of the fixture receipt shows 2.98 spent, two bought, one of them on bonus |
| `a product type nothing was bought under totals nothing` | dishwashing liquid alone in a month where nothing was bought returns no rows rather than zeroes |

### Then

On `ProductType`: `#products_with_latest_purchase` and `#totals_by_period`, both built on the same
`Product#purchases` query as step 1 so there is one definition of a purchase. Keep each method around
five lines; extract private helpers rather than growing one. Group in Ruby, not SQL — the volumes here are
a few hundred rows a year, and Ruby keeps the money arithmetic in `BigDecimal`.

`app/views/product_types/show.html.erb`: the products side by side with brand, latest paid price, latest
price per unit; then a table per month of spend, count and bonus count. Link each product to its page.

Locale keys `product_types.show.*` for the headings and `product_types.show.on_bonus_count`, in three
locales.

### Watch out

- A line whose pack size is unknown has no price per unit — `#paid_price_per_unit` returns nothing. Show
  a dash. A zero would read as free.
- Comparing a 300 g bag with a 250 g bag is exactly the point, so compare per unit, never per pack.
- Do not average a price across products of different brands and call it "the price of naturel chips".
  Spend and count per month are honest; a blended unit price is not.

Commit: `feat(groceries): compare the brands we buy a product type from`.

## Files this phase touches

- `app/models/product.rb` (`has_many :receipt_lines`, `#purchases`), `app/models/product_type.rb`
- `app/helpers/products_helper.rb`
- `app/views/products/show.html.erb`, `app/views/products/_price_chart.html.erb`,
  `app/views/product_types/show.html.erb`
- `config/locales/en.yml`, `nl.yml`, `it.yml`
- `test/models/product_test.rb`, `test/models/product_type_test.rb`,
  `test/integration/products_test.rb`, `test/integration/product_types_test.rb`

## Out of scope

- A charting library, JavaScript, or a canvas.
- Predicting prices or alerting on rises.
- Comparing prices between shops: only Albert Heijn data exists.
- Inflation adjustment.
