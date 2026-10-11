require "test_helper"

migration_path = Dir[File.expand_path("../../db/data/*_migrate_people_groups_and_legacy_owners.rb", __dir__)].first
require migration_path if migration_path

class MigratePeopleGroupsAndLegacyOwnersTest < ActiveSupport::TestCase
  test "up migrates legacy owners and recipients idempotently" do
    clear_managed_links

    2.times { MigratePeopleGroupsAndLegacyOwners.new.up }

    assert_equal "Etienne", Account.find_by!(owner: "etienne").person.name
    group = Group.find_by!(name: "Samen")

    assert_equal %w[Etienne Michelle], group.people.order(:name).pluck(:name)
    assert_equal group, Account.find_by!(owner: "samen").group
    assert_equal people(:etienne), Appropriation.find_by!(recipient: "Etienne", budget_year: 2026).person
  end

  test "migrates case-variant recipients to one person" do
    clear_managed_links
    Appropriation.find_by!(recipient: "Etienne", budget_year: 2026).update_columns(recipient: "ETIENNE")

    MigratePeopleGroupsAndLegacyOwners.new.up

    linked_people = Appropriation.where("LOWER(recipient) = ?", "etienne").map(&:person).uniq

    assert_equal 1, linked_people.size
    assert_equal "Etienne", linked_people.first.name
  end

  test "preserves household scopes and transaction types after migration" do
    clear_managed_links

    MigratePeopleGroupsAndLegacyOwners.new.up
    Current.user = users(:member)

    assert_equal accounts(:checking), Current.account
    assert_instance_of Debit, transactions(:debit_grocery).reload
    assert_instance_of Credit, transactions(:credit_salary).reload
    assert_instance_of Transfer, transactions(:transfer_savings).reload
    assert_equal BigDecimal("50.00"), transactions(:debit_grocery).amount
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
end
