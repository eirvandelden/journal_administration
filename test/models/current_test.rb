require "test_helper"

class CurrentTest < ActiveSupport::TestCase
  test "returns the Samen group account" do
    accounts(:checking).update_columns(owner: nil, group_id: nil)
    account = Account.create!(name: "Managed joint account", group: groups(:samen))
    first_group_account = Account.where(group_id: groups(:samen)).order(:id).first
    Current.user = users(:member)

    assert_equal account, first_group_account
    assert_equal first_group_account, Current.account

    groups(:samen).update!(name: "Household")

    assert_equal first_group_account, Current.account
  ensure
    Current.reset
  end
end
