require "test_helper"

class LinkableTest < ActiveSupport::TestCase
  # -- associations -----------------------------------------------------------

  test "linked_transfers returns transfers linked to a source transaction" do
    debit = transactions(:credit_grocery)

    assert_includes debit.linked_transfers, transactions(:transfer_for_grocery)
  end

  test "linked_sources returns source transactions linked to a transfer" do
    transfer = transactions(:transfer_for_grocery)

    assert_includes transfer.linked_sources, transactions(:credit_grocery)
  end

  # -- suggested_transfers ----------------------------------------------------

  test "suggested_transfers returns matching transfers within 5 days" do
    debit = transactions(:credit_grocery)
    debit.transaction_links.destroy_all

    suggestions = debit.suggested_transfers

    assert_includes suggestions, transactions(:transfer_for_grocery)
  end

  test "suggested_transfers excludes already linked transfers" do
    debit = transactions(:credit_grocery)

    suggestions = debit.suggested_transfers

    assert_not_includes suggestions, transactions(:transfer_for_grocery)
  end

  test "suggested_transfers excludes transfers linked to another source" do
    source = transactions(:credit_grocery)
    debit = Transaction.new(note: "Another grocery run", booked_at: source.booked_at + 1.day,
      interest_at: source.booked_at + 1.day)
    debit.mutations.build(account: accounts(:checking), amount: -50.00)
    debit.mutations.build(account: accounts(:albert_heijn), amount: 50.00)
    debit.save!

    suggestions = debit.suggested_transfers

    assert_not_includes suggestions, transactions(:transfer_for_grocery)
  end

  test "suggested_transfers excludes transfers outside the date window" do
    debit = transactions(:credit_grocery)
    debit.transaction_links.destroy_all
    old_transfer = transactions(:transfer_for_grocery)
    old_transfer.update_columns(booked_at: debit.booked_at + 10.days)

    suggestions = debit.suggested_transfers

    assert_not_includes suggestions, old_transfer
  end

  test "suggested_transfers returns empty for Transfer transactions" do
    transfer = transactions(:transfer_savings)

    assert_empty transfer.suggested_transfers
  end

  # -- link_balance -----------------------------------------------------------

  test "link_balance returns full amount when no transfers linked" do
    debit = transactions(:credit_grocery)
    debit.transaction_links.destroy_all

    assert_equal debit.amount, debit.link_balance
  end

  test "link_balance returns zero when fully covered" do
    debit = transactions(:credit_grocery)

    assert_equal 0, debit.link_balance
  end

  # -- fully_covered? --------------------------------------------------------

  test "fully_covered? returns true when balance is zero" do
    debit = transactions(:credit_grocery)

    assert debit.fully_covered?
  end

  test "fully_covered? returns false when balance is positive" do
    debit = transactions(:credit_grocery)
    debit.transaction_links.destroy_all

    assert_not debit.fully_covered?
  end

  # -- linked? ----------------------------------------------------------------

  test "linked? returns true when transaction has links" do
    debit = transactions(:credit_grocery)

    assert debit.linked?
  end

  test "linked? returns false when transaction has no links" do
    debit = transactions(:uncategorized_credit)

    assert_not debit.linked?
  end
end
