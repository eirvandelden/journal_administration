require "test_helper"

class TransactionLinkTest < ActiveSupport::TestCase
  # -- associations -----------------------------------------------------------

  test "belongs to source transaction" do
    link = transaction_links(:grocery_to_transfer)

    assert_equal transactions(:credit_grocery), link.source
  end

  test "belongs to transfer transaction" do
    link = transaction_links(:grocery_to_transfer)

    assert_equal transactions(:transfer_for_grocery), link.transfer
  end

  # -- validations ------------------------------------------------------------

  test "valid with a non-Transfer source and a Transfer transfer" do
    link = TransactionLink.new(
      source: transactions(:debit_salary),
      transfer: transactions(:transfer_savings)
    )

    assert link.valid?
  end

  test "invalid when transfer is not a Transfer type" do
    link = TransactionLink.new(
      source: transactions(:credit_grocery),
      transfer: transactions(:debit_salary)
    )

    assert_not link.valid?
    assert_includes link.errors[:transfer],
      I18n.t("activerecord.errors.models.transaction_link.attributes.transfer.must_be_transfer")
  end

  test "invalid when source is a Transfer type" do
    link = TransactionLink.new(
      source: transactions(:transfer_savings),
      transfer: transactions(:transfer_for_grocery)
    )

    assert_not link.valid?
    assert_includes link.errors[:source],
      I18n.t("activerecord.errors.models.transaction_link.attributes.source.must_not_be_transfer")
  end

  # -- uniqueness -------------------------------------------------------------

  test "duplicate source-transfer pair is invalid" do
    existing = transaction_links(:grocery_to_transfer)

    duplicate = TransactionLink.new(
      source: existing.source,
      transfer: existing.transfer
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:transfer_id], "has already been taken"
  end

  test "transfer already linked to another source is invalid" do
    existing = transaction_links(:grocery_to_transfer)

    duplicate = TransactionLink.new(
      source: transactions(:uncategorized_credit),
      transfer: existing.transfer
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:transfer_id], "has already been taken"
  end
end
