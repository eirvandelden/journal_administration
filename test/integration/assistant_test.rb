require "test_helper"

class AssistantTest < ActionDispatch::IntegrationTest
  KEEP_ME_POSTED = "subscriptions/listen"
  METHOD_NOT_FOUND = -32601

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

  test "the assistant is told when more accounts match than it was shown" do
    12.times { |number| Account.create!(name: "Bakery number #{number}") }

    answer = ask_assistant("find_accounts", query: "Bakery")

    assert_includes answer, "Showing 10 of 12"
  end

  test "the assistant is told when nothing matches what it searched for" do
    answer = ask_assistant("find_accounts", query: "Nowhere At All")

    assert_includes answer, "No account matches"
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

  test "an assistant probing for an open stream is told the app does not offer one" do
    get "/mcp", headers: assistant_headers

    assert_response :method_not_allowed
  end

  test "an assistant hanging up is answered rather than sent a web page" do
    delete "/mcp", headers: assistant_headers

    assert_response :success
  end

  test "an assistant asking to be kept posted is told the app cannot do that" do
    ask_to_be_kept_posted

    assert_response :not_found
    assert_equal METHOD_NOT_FOUND, JSON.parse(response.body).dig("error", "code")
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

  test "with no home network named the assistant is answered on this machine only" do
    host! "finances.vandelden.family"

    post_to_assistant

    assert_response :forbidden
  end

  test "off the home network the app says nothing about tokens, right or wrong" do
    only_on_home_network do
      host! "finances.vandelden.family"

      post_to_assistant(token: "not-a-real-token")

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

  def ask_to_be_kept_posted
    version = MCP::Configuration::LATEST_MODERN_PROTOCOL_VERSION

    post_to_assistant(
      method: KEEP_ME_POSTED,
      params: { notifications: {}, _meta: {
        "io.modelcontextprotocol/protocolVersion" => version,
        "io.modelcontextprotocol/clientCapabilities" => {}
      } },
      headers: {
        "Accept" => "application/json, text/event-stream",
        "MCP-Protocol-Version" => version,
        "Mcp-Method" => KEEP_ME_POSTED
      }
    )
  end

  def post_to_assistant(method: "tools/list", params: {}, token: @user.assistant_token, headers: {})
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: method, params: params }.to_json,
      headers: assistant_headers(token: token).merge(headers)
  end

  def assistant_headers(token: @user.assistant_token)
    headers = { "Content-Type" => "application/json", "Accept" => "application/json" }
    headers["Authorization"] = "Bearer #{token}" if token
    headers
  end
end
