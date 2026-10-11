require "test_helper"

migration_path = Dir[File.expand_path("../../db/data/*_migrate_people_groups_and_legacy_owners.rb", __dir__)].first
require migration_path if migration_path

class MigratePeopleGroupsAndLegacyOwnersTest < ActiveSupport::TestCase
  test "up migrates legacy owners and recipients idempotently" do
    clear_managed_links

    MigratePeopleGroupsAndLegacyOwners.new.up
    first_person_id = Person.find_by!(name: "Etienne").id
    MigratePeopleGroupsAndLegacyOwners.new.up

    canonical_person = Person.find_by!(name: "Etienne")

    assert_equal first_person_id, canonical_person.id
    assert_equal canonical_person, Account.find_by!(owner: "etienne").person
    group = Group.find_by!(name: "Samen")

    assert_equal %w[Etienne Michelle], group.people.order(:name).pluck(:name)
    assert_equal group, Account.find_by!(owner: "samen").group
    assert_equal canonical_person, Appropriation.find_by!(recipient: "Etienne", budget_year: 2026).person
  end

  test "migrates case-variant recipients to one person" do
    clear_managed_links
    first = appropriations(:birthday_etienne)
    second = appropriations(:christmas_etienne)
    first.update_columns(recipient: "Élodie")
    second.update_columns(recipient: "élodie")
    recipients = [ first, second ].index_with(&:recipient)

    MigratePeopleGroupsAndLegacyOwners.new.up

    first.reload
    second.reload

    assert_equal recipients.values, [ first.recipient, second.recipient ]
    assert_not_nil first.person_id
    assert_equal first.person_id, second.person_id
  end

  test "migrates named owners and Samen without changing legacy owners" do
    clear_managed_links
    michelle_account = Account.create!(name: "Michelle's legacy account", owner: :michelle)
    serena_account = Account.create!(name: "Serena's legacy account", owner: :serena)
    legacy_owners = Account.order(:id).pluck(:id, :owner)
    legacy_recipients = Appropriation.order(:id).pluck(:id, :recipient)

    MigratePeopleGroupsAndLegacyOwners.new.up

    assert_equal "Michelle", michelle_account.reload.person.name
    assert_equal "Serena", serena_account.reload.person.name
    assert_equal legacy_owners, Account.order(:id).pluck(:id, :owner)
    assert_equal legacy_recipients, Appropriation.order(:id).pluck(:id, :recipient)
    group = Group.find_by!(name: "Samen")

    assert_equal %w[Etienne Michelle], group.people.order(:name).pluck(:name)
    assert_equal group, Account.find_by!(owner: "samen").group
  end

  test "preserves household scopes and transaction types after migration" do
    clear_managed_links
    transactions(:gift_payment).update!(appropriation: appropriations(:birthday_etienne))
    legacy_history = legacy_history_snapshot

    MigratePeopleGroupsAndLegacyOwners.new.up
    Current.user = users(:member)

    assert_equal accounts(:checking), Current.account
    assert_includes Account.own, accounts(:checking)
    assert_includes Account.own, accounts(:savings)
    assert_instance_of Debit, transactions(:debit_grocery).reload
    assert_instance_of Credit, transactions(:credit_salary).reload
    assert_instance_of Transfer, transactions(:transfer_savings).reload
    assert_equal BigDecimal("50.00"), transactions(:debit_grocery).amount
    assert_equal legacy_history, legacy_history_snapshot
  ensure
    Current.reset
  end

  private

  def clear_managed_links
    Account.update_all(person_id: nil, group_id: nil)
    Appropriation.update_all(person_id: nil)
    GroupMembership.delete_all
    Group.delete_all
    Person.delete_all
  end

  def legacy_history_snapshot
    {
      accounts: Account.order(:id).pluck(:id, :owner),
      appropriations: Appropriation.order(:id).map do |appropriation|
        [ appropriation.id, appropriation.purpose, appropriation.recipient, appropriation.budget_year,
          appropriation.amount, appropriation.charged,
          appropriation.charges.map { |charge| [ charge.class.name, charge.id, charge.amount ] } ]
      end,
      transactions: Transaction.order(:id).pluck(
        :id, :type, :amount, :category_id, :debitor_account_id, :creditor_account_id, :appropriation_id
      ),
      transaction_links: TransactionLink.order(:id).pluck(:id, :source_transaction_id, :transfer_id),
      transaction_splits: TransactionSplit.order(:id).pluck(:id, :transaction_id, :category_id, :amount, :note)
    }
  end
end
