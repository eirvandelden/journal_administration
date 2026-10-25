require "test_helper"
require_relative "../test_helpers/assistant_requests"

# Keeps the MCP in step with the UI: a routed UI action either has a tool or a stated reason it has none.
# A feature that adds a route fails this test until it ships its tool in the same change.
class AssistantParityTest < ActionDispatch::IntegrationTest
  include AssistantRequests

  FRAMEWORK_PREFIXES = %w[rails/ turbo/ active_storage/ action_mailbox/].freeze
  FORM_PAGES = %w[new edit].freeze

  TOOL_FOR = {
    "accounts#index" => "find_accounts",
    "accounts/account_aliases#create" => "add_account_alias",
    "accounts/merchant_reassignments#create" => "move_transactions_to_merchants",
    "accounts/payment_providers#create" => "set_payment_provider",
    "appropriations#index" => "list_appropriations",
    "appropriations#create" => "set_appropriation",
    "appropriations#update" => "set_appropriation",
    "budgets#index" => "list_budgets",
    "budgets#show" => "budget_status",
    "budgets#create" => "start_budget",
    "budgets#update" => "set_budget_amount",
    "categories#index" => "list_categories",
    "product_types#index" => "list_product_types",
    "product_types#show" => "show_product_type",
    "product_types#create" => "create_product_type",
    "product_types#update" => "update_product_type",
    "products#index" => "list_products",
    "products#show" => "show_product",
    "products#update" => "classify_product",
    "receipts#index" => "list_receipts",
    "receipts#show" => "show_receipt",
    "receipts/payment_links#create" => "link_receipt_payment",
    "receipts/payment_links#destroy" => "unlink_receipt_payment",
    "transaction_splits#create" => "create_transaction_split",
    "transaction_splits#update" => "update_transaction_split",
    "transaction_splits#destroy" => "delete_transaction_split",
    "transaction_splits/appropriation_charges#update" => "charge_to_appropriation",
    "transactions#index" => "find_transactions",
    "transactions#show" => "show_transaction",
    "transactions#create" => "create_transaction",
    "transactions#update" => "update_transaction",
    "transactions#destroy" => "delete_transaction",
    "transactions/appropriation_charges#update" => "charge_to_appropriation"
  }.freeze

  LATER_SLICE = "a later parity slice: accounts, budgets, categories, appropriations and their gaps".freeze
  NOT_BOOKKEEPING = "not bookkeeping: people, groups, chattels and sessions stay with the app".freeze
  APP_ONLY = "belongs to the app itself, not the books: login, admin, PWA, preferences, health".freeze
  EXCLUDED = {
    "accounts#show" => LATER_SLICE, "accounts#create" => LATER_SLICE, "accounts#update" => LATER_SLICE,
    "accounts#destroy" => LATER_SLICE, "accounts/account_aliases#destroy" => LATER_SLICE,
    "accounts/merges#create" => LATER_SLICE, "accounts/payment_providers#destroy" => LATER_SLICE,
    "accounts/transaction_absorptions#create" => LATER_SLICE, "accounts/transactions_bulk#update" => LATER_SLICE,
    "appropriations#show" => LATER_SLICE, "appropriations#destroy" => LATER_SLICE,
    "budgets#destroy" => LATER_SLICE, "budgets/suggestions#create" => LATER_SLICE,
    "budgets/suggestions#update" => LATER_SLICE,
    "categories#show" => LATER_SLICE, "categories#create" => LATER_SLICE, "categories#update" => LATER_SLICE,
    "categories#destroy" => LATER_SLICE,
    "transaction_links#index" => LATER_SLICE, "transaction_links#create" => LATER_SLICE,
    "transaction_links#destroy" => LATER_SLICE,
    "transaction_splits/appropriation_charges#destroy" => "a later slice: removing a charge",
    "transactions/appropriation_charges#destroy" => "a later slice: removing a charge",
    "transactions/imports#create" => "bank-file import stays in the app",
    "chattels#index" => NOT_BOOKKEEPING, "chattels#show" => NOT_BOOKKEEPING, "chattels#create" => NOT_BOOKKEEPING,
    "chattels#update" => NOT_BOOKKEEPING, "chattels#destroy" => NOT_BOOKKEEPING,
    "people#index" => NOT_BOOKKEEPING, "people#show" => NOT_BOOKKEEPING, "people#create" => NOT_BOOKKEEPING,
    "people#update" => NOT_BOOKKEEPING, "people#destroy" => NOT_BOOKKEEPING,
    "groups#index" => NOT_BOOKKEEPING, "groups#show" => NOT_BOOKKEEPING, "groups#create" => NOT_BOOKKEEPING,
    "groups#update" => NOT_BOOKKEEPING, "groups#destroy" => NOT_BOOKKEEPING,
    "users#index" => NOT_BOOKKEEPING, "users#update" => NOT_BOOKKEEPING, "users#destroy" => NOT_BOOKKEEPING,
    "users/profiles#show" => NOT_BOOKKEEPING, "users/profiles#create" => NOT_BOOKKEEPING,
    "users/profiles#update" => NOT_BOOKKEEPING, "users/profiles#destroy" => NOT_BOOKKEEPING,
    "admin/dashboard#index" => APP_ONLY, "admin/users#index" => APP_ONLY, "admin/users#show" => APP_ONLY,
    "admin/users#create" => APP_ONLY, "admin/users#update" => APP_ONLY, "admin/users#destroy" => APP_ONLY,
    "appkit/first_runs#show" => APP_ONLY, "appkit/first_runs#create" => APP_ONLY,
    "appkit/preferences#update" => APP_ONLY, "appkit/push_subscriptions#create" => APP_ONLY,
    "appkit/push_subscriptions#destroy" => APP_ONLY, "appkit/pwa#manifest" => APP_ONLY,
    "appkit/pwa#service_worker" => APP_ONLY, "appkit/qr_code#show" => APP_ONLY,
    "appkit/sessions/transfers#show" => APP_ONLY, "appkit/sessions/transfers#update" => APP_ONLY,
    "appkit/sessions#create" => APP_ONLY, "appkit/sessions#destroy" => APP_ONLY,
    "assistant#create" => "this is the MCP endpoint itself",
    "dashboard#index" => "a page of totals; budget_status and find_transactions answer the same questions",
    "searches#index" => "a page of search results; find_accounts and find_transactions search",
    "todos#index" => "a page of open jobs; find_transactions with uncategorized and list_products with " \
      "unclassified answer the same questions"
  }.freeze

  setup do
    host! "localhost"
    @user = users(:admin)
    @user.regenerate_assistant_token
  end

  test "every routed UI action has a tool or a stated exclusion" do
    assert_empty unmapped_in(routed_actions), "Routed with no tool and no exclusion: #{unmapped_in(routed_actions)}"
  end

  test "an unmapped route is reported by name" do
    assert_equal [ "widgets#index" ], unmapped_in(routed_actions + [ "widgets#index" ])
  end

  test "every mapped tool is one the assistant lists" do
    missing = TOOL_FOR.values.uniq - listed_tools

    assert_empty missing, "Mapped to tools the assistant does not list: #{missing}"
  end

  test "no mapping or exclusion outlives its route" do
    stale = (TOOL_FOR.keys + EXCLUDED.keys) - routed_actions

    assert_empty stale, "Mapped or excluded, but no longer routed: #{stale}"
  end

  test "an action is never both mapped and excluded" do
    assert_empty TOOL_FOR.keys & EXCLUDED.keys
  end

  private

  def unmapped_in(actions) = actions - TOOL_FOR.keys - EXCLUDED.keys

  def listed_tools
    post_to_assistant

    JSON.parse(response.body).dig("result", "tools").pluck("name")
  end

  def routed_actions
    [ Rails.application.routes, Appkit::Engine.routes ].flat_map { |set| set.routes.filter_map { |route| action_of(route) } }
      .uniq.sort
  end

  def action_of(route)
    controller, action = route.defaults.values_at(:controller, :action)
    return if controller.nil? || FRAMEWORK_PREFIXES.any? { |prefix| controller.start_with?(prefix) }
    return if FORM_PAGES.include?(action)

    "#{controller}##{action}"
  end
end
