require "test_helper"

class AssistantTest < ActionDispatch::IntegrationTest
  setup do
    host! "localhost"
    @user = users(:admin)
    @user.regenerate_assistant_token
  end

  test "an assistant that presents no token is turned away" do
    post_to_assistant(token: nil)

    assert_response :unauthorized
  end

  test "an assistant that presents an unknown token is turned away" do
    post_to_assistant(token: "not-a-real-token")

    assert_response :unauthorized
  end

  test "an assistant acting for a deactivated user is turned away" do
    @user.update!(active: false)

    post_to_assistant

    assert_response :unauthorized
  end

  test "the assistant lists the categories it may file a transaction under" do
    answer = ask_assistant("list_categories")

    assert_includes answer, "Groceries - Supermarket"
  end

  test "the assistant files an uncategorized transaction under a category" do
    answer = ask_assistant("set_transaction_category",
      transaction_id: transactions(:uncategorized).id, category_id: categories(:supermarket).id)

    assert_equal categories(:supermarket), transactions(:uncategorized).reload.category
    assert_includes answer, "Groceries - Supermarket"
  end

  test "the assistant is told when the transaction it wants to file cannot be found" do
    answer = ask_assistant("set_transaction_category", transaction_id: 0, category_id: categories(:supermarket).id)

    assert_includes answer, "No transaction"
  end

  test "the assistant finds the transactions that still need a category" do
    answer = ask_assistant("find_uncategorized_transactions")

    assert_includes answer, "Uncategorized transaction"
    assert_not_includes answer, "Monthly salary"
  end

  test "the assistant finds the shop a transaction was paid to" do
    answer = ask_assistant("find_accounts", query: "Albert")

    assert_includes answer, "Albert Heijn B.V."
    assert_not_includes answer, "Jumbo"
  end

  test "the assistant teaches the books to recognise a shop by a new pattern" do
    answer = ask_assistant("add_account_alias", account_id: accounts(:jumbo).id, pattern: "JUMBO SUPERMARKTEN")

    assert accounts(:jumbo).account_aliases.exists?(pattern: "JUMBO SUPERMARKTEN")
    assert_includes answer, "Jumbo B.V."
  end

  test "the assistant cannot give a recognition pattern to one of our own accounts" do
    answer = ask_assistant("add_account_alias", account_id: accounts(:checking).id, pattern: "OUR OWN ACCOUNT")

    assert_empty accounts(:checking).account_aliases
    assert_includes answer, "must belong to an external account"
  end

  test "the assistant answers on the home network host it is configured for" do
    only_on_home_network do
      host! "finances.home.arpa"

      post_to_assistant

      assert_response :success
    end
  end

  test "the assistant stays silent on any other host" do
    only_on_home_network do
      host! "finances.vandelden.family"

      post_to_assistant

      assert_response :forbidden
    end
  end

  private

  def only_on_home_network
    Rails.configuration.x.assistant_host = "finances.home.arpa"
    yield
  ensure
    Rails.configuration.x.assistant_host = nil
  end

  def ask_assistant(tool, arguments = {})
    post_to_assistant(method: "tools/call", params: { name: tool, arguments: arguments })

    assert_response :success
    JSON.parse(response.body).dig("result", "content").map { |part| part["text"] }.join("\n")
  end

  def post_to_assistant(method: "tools/list", params: {}, token: @user.assistant_token)
    headers = { "Content-Type" => "application/json", "Accept" => "application/json" }
    headers["Authorization"] = "Bearer #{token}" if token

    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: method, params: params }.to_json, headers: headers
  end
end
