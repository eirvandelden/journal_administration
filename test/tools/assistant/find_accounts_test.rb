require "test_helper"

class Assistant::FindAccountsTest < ActiveSupport::TestCase
  test "call reports current managed owner" do
    household = groups(:samen)
    person = people(:etienne)
    group_account = Account.create!(name: "Managed joint account", owner: nil, group: household)
    person_account = Account.create!(name: "Managed personal account", owner: nil, person:)
    household.update!(name: "Delden Household")
    person.update!(name: "E. van Delden")

    group_reply = Assistant::FindAccounts.call(query: group_account.name, server_context: nil).content.first[:text]
    person_reply = Assistant::FindAccounts.call(query: person_account.name, server_context: nil).content.first[:text]

    assert_includes group_reply, "Delden Household"
    assert_includes person_reply, "E. van Delden"
    assert_not_includes group_reply, "Samen"
    assert_not_includes person_reply, "Etienne"
  end

  test "call does not query owners once per account" do
    one = query_count_for_accounts(1)
    many = query_count_for_accounts(4)

    assert_equal one, many
  end

  private

  def query_count_for_accounts(count)
    count.times { |index| Account.create!(name: "Counted #{count} #{index}", person: people(:etienne)) }
    queries = []
    counter = ->(*, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      Assistant::FindAccounts.call(query: "Counted #{count}", server_context: nil)
    end
    queries.size
  end
end
