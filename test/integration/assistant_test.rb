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

  test "the assistant lists the budgets and when each one runs" do
    answer = ask_assistant("list_budgets")

    assert_includes answer, "#{budgets(:active_budget).id}: 2026-03-01 onwards, running now, 2 categories planned"
    assert_includes answer, "#{budgets(:past_budget).id}: 2026-01-01 to 2026-01-31, finished, nothing planned"
  end

  test "the assistant changes what a category may cost" do
    budget = budgets(:active_budget)

    answer = ask_assistant("set_budget_amount",
      budget_id: budget.id, category_id: categories(:groceries).id, amount: 250)

    assert_equal 250, planned_for(budget, :groceries)
    assert_includes answer, "Groceries may cost 250.00 a month"
  end

  test "the assistant starts a budget and says which one that closed" do
    starts_on = Date.current.to_s

    answer = ask_assistant("start_budget", starts_on: starts_on)

    assert Budget.exists?(starts_at: Date.current.beginning_of_day)
    assert_includes answer, "starts #{starts_on}"
    assert_includes answer, "closed budget ##{budgets(:future_budget).id}"
  end

  test "the assistant cannot start a second budget on a day one already starts" do
    answer = ask_assistant("start_budget", starts_on: budgets(:active_budget).starts_at.to_date.to_s)

    assert_equal 3, Budget.count
    assert_includes answer, "has already been taken"
  end

  test "the assistant is told when the day it gave to start from cannot be read" do
    answer = ask_assistant("start_budget", starts_on: "next Monday")

    assert_equal 3, Budget.count
    assert_includes answer, "Could not read"
  end

  test "the assistant plans a category the budget did not cover yet" do
    budget = budgets(:active_budget)

    ask_assistant("set_budget_amount", budget_id: budget.id, category_id: categories(:housing).id, amount: 800)

    assert_equal 800, planned_for(budget, :housing)
  end

  test "the assistant may not change a budget that has already finished" do
    budget = budgets(:past_budget)

    answer = ask_assistant("set_budget_amount",
      budget_id: budget.id, category_id: categories(:groceries).id, amount: 50)

    assert_nil planned_for(budget, :groceries)
    assert_includes answer, "already finished"
  end

  test "the assistant is told a category inside another cannot carry an amount of its own" do
    answer = ask_assistant("set_budget_amount",
      budget_id: budgets(:active_budget).id, category_id: categories(:supermarket).id, amount: 100)

    assert_includes answer, "must be a top-level category"
  end

  test "the assistant says what was planned, what was spent and what is left" do
    plan = budget_starting_this_month(groceries: 100)

    answer = ask_assistant("budget_status", start_date: plan[:from], end_date: plan[:until])

    assert_includes answer, "Groceries: planned 100.00, spent 12.50, 87.50 left"
  end

  test "the assistant says money coming in came in, rather than calling it spending" do
    plan = budget_starting_this_month(income: 4000)

    answer = ask_assistant("budget_status", start_date: plan[:from], end_date: plan[:until])

    assert_includes answer, "Income: expected 4000.00, came in 3000.00, 1000.00 still to come"
  end

  test "the assistant says how far over the plan the spending went" do
    plan = budget_starting_this_month(groceries: 10)

    answer = ask_assistant("budget_status", start_date: plan[:from], end_date: plan[:until])

    assert_includes answer, "Groceries: planned 10.00, spent 12.50, 2.50 over"
  end

  test "the assistant is told when no budget covers the period it asked about" do
    answer = ask_assistant("budget_status", start_date: "2001-01-01", end_date: "2001-01-30")

    assert_includes answer, "No budget covers 2001-01-01 to 2001-01-30"
  end

  test "the assistant is told when the dates it gave cannot be read" do
    answer = ask_assistant("budget_status", start_date: "last Tuesday", end_date: "whenever")

    assert_includes answer, "Could not read"
  end

  test "the assistant lists the categories it may file a transaction under" do
    answer = ask_assistant("list_categories")

    assert_includes answer, "Groceries - Supermarket"
  end

  test "the assistant is told when more categories exist than it was shown" do
    more_categories_than_fit_in_one_answer

    answer = ask_assistant("list_categories")

    assert_includes answer, "Showing #{Assistant::ListCategories::HIGHEST_COUNT} of"
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

  test "the assistant is told when the category it wants to file under cannot be found" do
    answer = ask_assistant("set_transaction_category", transaction_id: transactions(:uncategorized).id, category_id: 0)

    assert_includes answer, "No category"
    assert_nil transactions(:uncategorized).reload.category
  end

  test "a problem reads as a problem and not as an answer" do
    assert refused?("set_transaction_category", transaction_id: 0, category_id: 0)
    assert_not refused?("list_categories")
  end

  test "the assistant is told when the account it wants to teach cannot be found" do
    answer = ask_assistant("add_account_alias", account_id: 0, pattern: "SOMEWHERE")

    assert_includes answer, "No account"
  end

  test "the assistant asking for fewer transactions than one is given one" do
    answer = ask_assistant("find_uncategorized_transactions", limit: 0)

    assert_equal 1, answer.lines.count
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
    previous_host = Rails.configuration.x.assistant_host
    Rails.configuration.x.assistant_host = "finances.home.arpa"
    yield
  ensure
    Rails.configuration.x.assistant_host = previous_host
  end

  def ask_assistant(tool, arguments = {})
    post_to_assistant(method: "tools/call", params: { name: tool, arguments: arguments })

    assert_response :success
    JSON.parse(response.body).dig("result", "content").map { |part| part["text"] }.join("\n")
  end

  def planned_for(budget, category)
    budget.budget_categories.find_by(category: categories(category))&.amount
  end

  # A budget's amounts are stated per month and scaled to the period asked about, so a period of
  # exactly thirty days is the one where planned and stated are the same number.
  def budget_starting_this_month(amounts)
    from = Time.current.beginning_of_month
    budget = Budget.create!(starts_at: from, ends_at: from + 29.days)

    amounts.each { |category, amount| budget.budget_categories.create!(category: categories(category), amount:) }

    { from: from.to_date.to_s, until: budget.ends_at.to_date.to_s }
  end

  def more_categories_than_fit_in_one_answer
    now = Time.current
    extra = (Assistant::ListCategories::HIGHEST_COUNT + 1 - Category.count).times.map do |number|
      { name: "Spare category #{number}", direction: 0, created_at: now, updated_at: now }
    end

    Category.insert_all(extra)
  end

  def refused?(tool, arguments = {})
    post_to_assistant(method: "tools/call", params: { name: tool, arguments: arguments })

    JSON.parse(response.body).dig("result", "isError").present?
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
