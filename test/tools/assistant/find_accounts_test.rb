require "test_helper"

class Assistant::FindAccountsTest < ActiveSupport::TestCase
  test "call reports current managed owner" do
    response = Assistant::FindAccounts.call(query: "Gezamenlijke", server_context: nil)

    assert_includes response.content.first.text, "ours"
    assert_predicate accounts(:checking), :household_owned?
  end
end
