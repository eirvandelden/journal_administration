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

  test "does not abort when Unicode case variants share a purpose and year, and links the earlier one" do
    clear_managed_links
    first = appropriations(:birthday_etienne)
    second = appropriations(:christmas_etienne)
    first.update_columns(recipient: "Élodie", purpose: "Gift")
    second.update_columns(recipient: "élodie", purpose: "Gift")
    snapshot = Appropriation.order(:id).pluck(:id, :recipient, :amount)

    assert_nothing_raised { MigratePeopleGroupsAndLegacyOwners.new.up }

    assert_equal snapshot, Appropriation.order(:id).pluck(:id, :recipient, :amount)
    assert_not_nil first.reload.person_id
  end

  test "links both Unicode case variants to one person and flags the later row" do
    clear_managed_links
    first = appropriations(:birthday_etienne)
    second = appropriations(:christmas_etienne)
    first.update_columns(recipient: "Élodie", purpose: "Gift")
    second.update_columns(recipient: "élodie", purpose: "Gift")
    charge = transactions(:gift_payment)
    charge.update_columns(appropriation_id: second.id)
    snapshot = Appropriation.order(:id).pluck(:id, :recipient, :amount)

    MigratePeopleGroupsAndLegacyOwners.new.up
    MigratePeopleGroupsAndLegacyOwners.new.up

    assert_equal snapshot, Appropriation.order(:id).pluck(:id, :recipient, :amount)
    assert_not_nil first.reload.person_id
    assert_equal first.person_id, second.reload.person_id
    assert_equal [ false, true ], [ first.legacy_duplicate, second.legacy_duplicate ]
    assert_equal second.id, charge.reload.appropriation_id
    assert_equal [ charge ], second.charges
    assert_equal charge.amount, second.charged
  end

  test "a person rename shows the new name on both case-variant rows" do
    clear_managed_links
    first = appropriations(:birthday_etienne)
    second = appropriations(:christmas_etienne)
    first.update_columns(recipient: "Élodie", purpose: "Gift")
    second.update_columns(recipient: "élodie", purpose: "Gift")

    MigratePeopleGroupsAndLegacyOwners.new.up
    first.reload.person.update!(name: "Elodie Renamed")

    assert_equal [ "Elodie Renamed", "Elodie Renamed" ], [ first.reload.recipient_name, second.reload.recipient_name ]
    assert_equal [ "Élodie", "élodie" ], [ first.recipient, second.recipient ]
  end

  test "creates household people only for legacy owners used by an account" do
    clear_managed_links
    Appropriation.where(recipient: %w[Serena Cosimo Chiara]).find_each do |appropriation|
      appropriation.update_columns(recipient: "Outsider #{appropriation.id}")
    end

    MigratePeopleGroupsAndLegacyOwners.new.up

    assert_empty Person.where(name: %w[Serena Cosimo Chiara])
    assert_equal %w[Etienne Michelle], Person.where(household: true).order(:name).pluck(:name)
  end

  test "migrates named owners and Samen without changing legacy owners" do
    clear_managed_links
    michelle_account = Account.create!(name: "Michelle's legacy account", owner: nil)
    michelle_account.update_columns(owner: Account.owners.fetch("michelle"))
    serena_account = Account.create!(name: "Serena's legacy account", owner: nil)
    serena_account.update_columns(owner: Account.owners.fetch("serena"))
    michelle_account.update!(name: "Edited Michelle legacy account")

    assert_equal [ [], [], 0, 0 ], [
      Person.pluck(:id), Group.pluck(:id),
      Account.where("person_id IS NOT NULL OR group_id IS NOT NULL").count,
      Appropriation.where.not(person_id: nil).count
    ]

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
    whole_payment = transactions(:gift_payment)
    whole_payment.update!(appropriation: appropriations(:birthday_etienne))
    split_payment = transactions(:webshop_sinterklaas)
    split_part = split_payment.transaction_splits.create!(
      amount: 6000, category: categories(:gifts), appropriation: appropriations(:birthday_etienne), remainder: false
    )
    split_payment.ensure_remainder_split

    assert_equal 10_000, appropriations(:birthday_etienne).charged

    clear_managed_links

    assert_equal [ nil, 0, 0 ], [
      appropriations(:birthday_etienne).reload.person_id,
      Account.where("person_id IS NOT NULL OR group_id IS NOT NULL").count,
      Appropriation.where.not(person_id: nil).count
    ]

    legacy_history = legacy_history_snapshot

    MigratePeopleGroupsAndLegacyOwners.new.up
    Current.user = users(:member)

    assert_equal accounts(:checking), Current.account
    assert_empty [ accounts(:checking), accounts(:savings) ] - Account.own
    assert_equal [ Debit, Credit, Transfer ], [
      transactions(:debit_grocery).reload.class,
      transactions(:credit_salary).reload.class,
      transactions(:transfer_savings).reload.class
    ]
    assert_equal 5000, transactions(:debit_grocery).amount
    assert_equal legacy_history, legacy_history_snapshot
    assert_equal [ appropriations(:birthday_etienne), appropriations(:birthday_etienne), "Etienne" ], [
      whole_payment.reload.appropriation,
      split_part.reload.appropriation,
      appropriations(:birthday_etienne).reload.person.name
    ]
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
      transaction_splits: TransactionSplit.order(:id).pluck(
        :id, :transaction_id, :category_id, :amount, :note, :appropriation_id, :remainder
      )
    }
  end
end
