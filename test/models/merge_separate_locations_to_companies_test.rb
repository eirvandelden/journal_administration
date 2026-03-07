require "test_helper"
require Rails.root.join("db/data/20240701202724_merge_separate_locations_to_companies").to_s

class MergeSeparateLocationsToCompaniesTest < ActiveSupport::TestCase
  test "up works with mutation schema and repoints matched account mutations" do
    migration = MergeSeparateLocationsToCompanies.new
    source_account = Account.create!(name: "AH to go EINDHOVEN")

    transaction = Transaction.new(booked_at: Time.current, interest_at: Time.current)
    transaction.mutations.build(account: accounts(:checking), amount: -10)
    transaction.mutations.build(account: source_account, amount: 10)
    transaction.save!

    assert_nothing_raised { migration.up }

    target_account = Account.find_by!(name: "Albert Heijn B.V.")
    source_mutation = transaction.reload.mutations.find_by(amount: 10)

    assert_equal target_account.id, source_mutation.account_id
  end
end
