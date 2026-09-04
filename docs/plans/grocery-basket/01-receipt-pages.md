# Phase 01 — See and settle receipts

Read `00-context.md` first.

## Why

Receipts exist in the database but nowhere in the app. Nobody can see which invoices are known, and a
receipt whose payment could not be identified automatically is stuck: `Receipt#matching_payment` returns
nothing when two payments would fit or none does, and there is no way for a person to decide.

## Decide with the owner before starting

- Where receipts belong in the main navigation and under which word. The navigation uses
  `t('main_nav.<key>', model: Model.model_name.human)` with an emoji in the translation, so the emoji is
  part of the decision (`🧾` is unused).
- Whether a receipt may be deleted in the app at all, or only replaced by re-importing. The steps below
  assume no delete.

## Step 1 — Receipt list and detail page

### Tests first

`test/integration/receipts_test.rb`, signing in through `sign_in_as users(:member)` as the other
integration tests do:

| Test name | Asserts |
| --- | --- |
| `the receipts page lists the invoices we have` | `get receipts_path` succeeds; a row holds "Albert Heijn B.V." and `number_to_currency(50.00)` |
| `the receipts page links each invoice to its own page` | `assert_select "a[href=?]", receipt_path(receipts(:albert_heijn_friday))` |
| `a receipt shows what was in the basket` | `get receipt_path(...)`; `assert_select "td", text: "AH Naturel Ribbelchips"`; the basket heading `I18n.t("receipts.basket.heading", locale: :en)` is present |
| `a receipt says which payment settled it` | after `receipts(:albert_heijn_friday).update!(payment: transactions(:debit_grocery))`, the page links to `transaction_path(transactions(:debit_grocery))` |
| `a receipt that nothing has settled says so` | with no payment, `I18n.t("receipts.show.not_settled", locale: :en)` appears |
| `a receipt links to the invoice it came from` | after attaching a PDF, a link with `I18n.t("receipts.basket.view_invoice", locale: :en)` appears |

The invoice-link assertion belongs here even though `_basket` already renders it, because the receipt
page is where a person goes looking for it.

### Then

`config/routes.rb`, next to the other resources:

```ruby
resources :receipts, only: %i[index show]
```

`app/controllers/receipts_controller.rb` — follow `CategoriesController`'s shape: a class-level comment,
`before_action :set_receipt, only: %i[show]`, YARD-style `@return [void]` on the actions, `private`
section at the bottom.

- `index`: newest first by `issued_on`, paginated the way `TransactionsController` does it —
  `set_page_and_extract_portion_from Receipt.order(issued_on: :desc), per_page: [20]` — with
  `.includes(:shop, :payment)` so the table does not query per row.
- `show`: `@receipt` with `.includes(lines: { product: :product_type })`, so the basket partial and the
  price-per-unit column cost one query, not one per line.

`app/views/receipts/index.html.erb`:

- `<h1>` from `Receipt.model_name.human(count: 2)`.
- A table: date (`l receipt.issued_on`), shop, total (`number_to_currency`), whether it is settled, and
  a link to the receipt. Follow the markup habits of `app/views/transactions/_table.html.erb`.
- `render "shared/pagination", page: @page` above and below the table, as the todo page does.
- An empty state paragraph when there are no receipts at all.

`app/views/receipts/show.html.erb`:

- `<header>` with shop and date as the `<h1>`, mirroring `transactions/show.html.erb`.
- A `<dl>` with shop, invoice date, invoice total, and the basket total (`@receipt.basket_total`). When
  the two differ, say what the difference is — a bag fee or a deposit is the usual reason, and hiding it
  would make the page look wrong rather than the invoice.
- `<%= render "receipts/basket", receipt: @receipt %>`. Do not duplicate that table.
- A section for the payment: a link to the transaction when settled, otherwise the picker from step 2.

Locale keys, alphabetically placed, in `en`, `nl` and `it`:

```
receipts.index.heading, receipts.index.date, receipts.index.shop, receipts.index.total,
receipts.index.settled, receipts.index.unsettled, receipts.index.empty,
receipts.show.invoice_total, receipts.show.basket_total, receipts.show.difference,
receipts.show.settled_by, receipts.show.not_settled,
main_nav.receipts
```

Also add `activerecord.models.receipt` and `activerecord.models.receipt_line` (with the `one`/`other`
plural forms the other models use there) — `model_name.human` needs them, and `test/i18n_test.rb`
checks all three locales carry the same keys.

Navigation: one `<li>` in `app/views/layouts/application.html.erb` next to chattels, with the same
`aria-current` treatment.

### Verify

New tests pass; `bin/rails test` shows no failures beyond the two known chattels ones; `bundle exec
rubocop` and `bundle exec herb lint` clean on every touched file. The partial already declares strict
locals; any new partial needs its own `<%# locals: (...) %>` line.

Commit: `feat(groceries): show the receipts and what each one held`.

## Step 2 — Settle an unmatched receipt

### Tests first

Same file:

| Test name | Asserts |
| --- | --- |
| `an unsettled receipt offers the payments that could have settled it` | the page has a form containing `transactions(:debit_grocery).id` as a choice |
| `choosing a payment settles the receipt and splits it by the basket` | posting the choice redirects to the receipt; `receipt.reload.payment` is the chosen payment; the payment's explicit splits are Groceries 2.98 and Household 3.49 |
| `a receipt that is already settled offers no picker` | with a payment set, the picker's submit button is absent |
| `a receipt with no possible payment says so` | after `receipt.update!(total_amount: 999.99)`, `I18n.t("receipts.show.no_candidates", locale: :en)` appears and no form is rendered |
| `a basket costing more than the payment is not split` | with a line raised above the payment amount, posting the choice leaves the payment's splits untouched and shows `I18n.t("receipts.payment_links.create.basket_exceeds_payment", locale: :en)` |

The 2.98 and 3.49 figures come from the fixtures described in `00-context.md`: two chips lines under
Groceries and one dishwashing liquid line under Household.

### Then

- `Receipt#fitting_payments` is private today and returns exactly the candidate list the picker needs.
  Make it public and leave `#matching_payment` alone — that one is what the import uses, and it must keep
  refusing to choose between two.
- Route, nested so the receipt owns it:

```ruby
resources :receipts, only: %i[index show] do
  scope module: "receipts" do
    resource :payment_link, only: %i[create]
  end
end
```

  That `scope module:` form is how `accounts` already nests its own controllers.

- `app/controllers/receipts/payment_links_controller.rb#create`: find the receipt, assign the payment
  from `params.require(:receipt).permit(:payment_id)`, then call `receipt.rewrite_payment_splits`.
  Redirect back to the receipt with a notice when it returns true, and with an alert naming the mismatch
  when it returns false. Restrict the assignable payments to `receipt.fitting_payments` so a crafted
  form cannot attach an unrelated transaction.
- The picker section in `show.html.erb`: a `button_to` per candidate, or a radio list with one submit —
  either is fine, but each candidate must show date, amount and the other account, or the choice is
  meaningless.
- Locale keys: `receipts.show.candidates`, `receipts.show.no_candidates`,
  `receipts.payment_links.create.success`, `receipts.payment_links.create.basket_exceeds_payment`, in
  three locales.

### Watch out

- `rewrite_payment_splits` destroys the payment's existing splits before writing its own. On a payment
  someone had split by hand, those edits are gone — that is the agreed behaviour, but the notice should
  make it obvious that the splits now follow the basket.
- It returns `false` and writes nothing when the basket costs more than the payment. Never report that as
  success.

Commit: `feat(groceries): let a person settle a receipt against its payment`.

## Files this phase touches

- `config/routes.rb`
- `app/controllers/receipts_controller.rb`, `app/controllers/receipts/payment_links_controller.rb`
- `app/views/receipts/index.html.erb`, `app/views/receipts/show.html.erb`
- `app/views/layouts/application.html.erb`
- `app/models/receipt.rb` — one method's visibility, nothing else
- `config/locales/en.yml`, `nl.yml`, `it.yml`
- `test/integration/receipts_test.rb`

## Out of scope

- Creating or editing receipts and their lines by hand.
- Deleting receipts, unless the owner asked for it in the conversation above.
- Unsettling a receipt once settled — nobody has needed it yet.
- Products, product types, price history: later phases.
