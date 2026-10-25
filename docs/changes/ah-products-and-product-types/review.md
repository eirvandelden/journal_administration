# Review: ah-products-and-product-types

## Round 1 — 2026-10-25T10:08:55Z — d1c87d3 (codex)

- [ ] Important: Order-number payment matching does not check the shop account, so another credit carrying the same `AE<order number>` token can be linked as the delivery payment — `app/models/receipt/payment_matching.rb:57` → fixed (Match order-number payments only among the shop's credits)

## Round 2 — 2026-10-25T10:09:34Z — d1c87d3 (claude)

- [ ] Nit: `ClassifyProduct` says "Kept the type X, as already set" even when the caller asked for that same type, so the answer reads as a refusal where nothing was refused; compare the requested value before reporting it kept — `app/tools/assistant/classify_product.rb:44` → fixed (Say a value was kept only when the caller asked for another)
- [ ] Nit: `ImportAlbertHeijnMail.describe` calls `receipt.lines.count` (an extra COUNT query) although it already loads the lines for the products; use the loaded size — `app/tools/assistant/import_albert_heijn_mail.rb:34` → fixed (Count the loaded lines instead of querying again)
- [ ] Nit: Law of Demeter chains reach through one object into another: `existing.category.full_name` and `payment.booked_at.to_date`; a method on `ProductType` and `Transaction` would tell instead of ask — `app/tools/assistant/create_product_type.rb:24`, `app/tools/assistant/link_deliveries_to_payments.rb:21` → dismissed: both chains sit in answer text only; a delegating method on ProductType and Transaction for one caller each adds public surface without a second use

Compliance: every test named in `plan.md`'s `## Proof` was looked up only by file list in the diff; the test suite and rubocop could not run here (Bundler refuses: Ruby 4.0.6 active, Gemfile asks for 4.0.7), so no run result backs this round. No existing test was seen weakened, skipped or deleted. No glossary file exists in the repository, so the avoided-word check had nothing to compare. Every public method in the diff carries an inline signature.

## Round 3 — 2026-10-25T10:13:51Z — 07195a6 (codex)

No findings.

## Round 4 — 2026-10-25T10:14:20Z — 07195a6 (claude)

Round 1 and 2 closures checked against the code: the shop scope in `ordered_payments` and `door_card_payments`, the kept-only-when-different check, and the loaded-lines count all hold. The dismissal stands.

- [ ] Nit: N+1 read in `describe`: `product.unclassified?` reads `product_type` lazily for each line, while only `:product` is preloaded; preload `product: :product_type` — `app/tools/assistant/import_albert_heijn_mail.rb:34` → fixed (Preload product types when describing an imported receipt)
- [ ] Nit: `link_payments` runs `ordered_payments` (and `door_card_payments`) once per delivery, so queries grow with the number of unlinked deliveries; no Proof line caps it, but a first import links many at once — `app/models/receipt/payment_matching.rb:30` → dismissed: the plan states this cost (two queries per delivery, a few thousand for the first run of about 175 deliveries) and accepts it for a one-off job
- [ ] Nit: `kept_brand?` compares the raw brand, but `Product#fill_in` stores it stripped, so a request of " AH" for a product already branded "AH" still answers "Kept the brand AH" — `app/tools/assistant/classify_product.rb:51` → fixed (Compare the stripped brand when saying one was kept)

Compliance: every test named in `## Proof` and in the per-file list exists in the diff by file; the owner reports 1452 runs, 0 failures, rubocop and brakeman clean, which I could not rerun here. No existing test was seen weakened, skipped or deleted. No glossary file exists, so the avoided-word check had nothing to compare. Public methods carry inline signatures, except the tools' `self.call` entry points, which follow the convention of the existing tools.
