require "test_helper"

class CurrentTest < ActiveSupport::TestCase
  test "returns the Samen group account" do
    groups(:samen).update!(name: "Household")
    Current.user = users(:member)

    assert_equal accounts(:checking), Current.account
  ensure
    Current.reset
  end
end
