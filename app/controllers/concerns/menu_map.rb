# Draws this household's menu map for the current request.
#
# One map feeds the rail, the hub column, the landing pages and search.
module MenuMap
  extend ActiveSupport::Concern

  included do
    helper_method :menu, :tile_text
  end

  # The menu map placed on this request, built once per request.
  #: () -> Appkit::Menu
  def menu
    @menu ||= Appkit::Menu.new(hubs: menu_hubs, controller_path: controller_path, params: request.parameters)
  end

  # i18n-tasks-use t("menu.pages.appropriations.tile")
  # i18n-tasks-use t("menu.pages.all.tile")
  # i18n-tasks-use t("menu.pages.chattels.tile")
  # i18n-tasks-use t("menu.pages.classify_accounts.tile")
  # i18n-tasks-use t("menu.pages.classify_products.tile")
  # i18n-tasks-use t("menu.pages.consolidate.tile")
  # i18n-tasks-use t("menu.pages.products.tile")
  # i18n-tasks-use t("menu.pages.receipts.tile")
  # What a page's tile says: its count written out, also when 0, or its summary.
  #: (Appkit::Menu::Page) -> String?
  def tile_text(page)
    count = page.count
    key = page.key
    count.nil? ? page.summary : t("menu.pages.#{key}.tile", count: count)
  end

  # The record's own page, keeping the origin when there is one.
  #: (ActiveRecord::Base) -> String
  def carried_path(record)
    menu.carry(polymorphic_path(record))
  end

  private
    #: () -> Array[Appkit::Menu::Hub]
    def menu_hubs
      [ overview_hub, processing_hub, planning_hub, records_hub, shopping_hub, profile_hub, setup_hub ]
    end

    #: () -> Appkit::Menu::Hub
    def profile_hub
      menu_hub(:profile, "👤", hub_path(:profile), hub_landing(:profile), pages: [
        *profile_details_pages,
        menu_page(:preferences, edit_preferences_path, %w[appkit/preferences]),
        menu_page(:setup, hub_path(:setup), []),
        menu_page(:sign_out, session_path, [], verb: :delete)
      ])
    end

    # Gegevens edits the signed-in user's own profile, so it needs a user.
    #: () -> Array[Appkit::Menu::Page]
    def profile_details_pages
      user = Current.user
      return [] unless user

      [ menu_page(:profile_details, edit_user_profile_path(user), %w[users/profiles]) ]
    end

    #: () -> Appkit::Menu::Hub
    def overview_hub
      menu_hub(:overview, "🏠", dashboard_index_path, { "controller" => "dashboard" }, controllers: %w[dashboard])
    end

    #: () -> Appkit::Menu::Hub
    def processing_hub
      open_pages = processing_open_pages
      menu_hub(:processing, "📥", hub_path(:processing), hub_landing(:processing),
        action: menu_link(t("menu.hubs.processing.import"), new_transactions_import_path),
        pages: [
          *open_pages,
          menu_page(:import, new_transactions_import_path, %w[transactions/imports]),
          menu_page(:all, todo_path, %w[todos], count: -> { open_pages.sum { |page| page.count.to_i } })
        ])
    end

    # The three lists of open items; Alles adds up their counts.
    #: () -> Array[Appkit::Menu::Page]
    def processing_open_pages
      [
        menu_page(:consolidate, transactions_path(filter: :no_category), %w[transactions],
          filter: { "filter" => "no_category" }, count: -> { Transaction.uncategorized.count }),
        menu_page(:classify_accounts, accounts_path(filter: :untouched), %w[accounts],
          filter: { "filter" => "untouched" }, count: -> { Account.untouched.count }),
        menu_page(:classify_products, products_path(filter: :unclassified), %w[products],
          filter: { "filter" => "unclassified" }, count: -> { Product.unclassified.count })
      ]
    end

    #: () -> Appkit::Menu::Hub
    def planning_hub
      menu_hub(:planning, "🗓️", hub_path(:planning), hub_landing(:planning), pages: [
        menu_page(:budgets, budgets_path, %w[budgets budgets/suggestions], summary: -> { budget_summary_text }),
        menu_page(:appropriations, appropriations_path, %w[appropriations],
          tile_path: appropriations_path(filter: :money_left),
          count: -> { Appropriation.of_year(Date.current.year).with_money_left.count })
      ])
    end

    #: () -> Appkit::Menu::Hub
    def records_hub
      menu_hub(:records, "🗄️", hub_path(:records), hub_landing(:records), pages: [
        menu_page(:journal, transactions_path, %w[transactions transaction_links transaction_splits
          transactions/appropriation_charges transaction_splits/appropriation_charges]),
        menu_page(:accounts, accounts_path, %w[accounts accounts/transactions_bulks accounts/transaction_absorptions
          accounts/payment_providers accounts/merchant_reassignments accounts/merges accounts/account_aliases]),
        menu_page(:chattels, chattels_path, %w[chattels],
          tile_path: chattels_path(filter: :warranty_ending), count: -> { Chattel.warranty_ending.count })
      ])
    end

    #: () -> Appkit::Menu::Hub
    def shopping_hub
      menu_hub(:shopping, "🛒", hub_path(:shopping), hub_landing(:shopping), pages: [
        menu_page(:receipts, receipts_path, %w[receipts receipts/payment_links],
          tile_path: receipts_path(filter: :without_payment), count: -> { Receipt.without_payment.count }),
        menu_page(:products, products_path, %w[products],
          tile_path: products_path(filter: :unclassified), count: -> { Product.unclassified.count })
      ])
    end

    #: () -> Appkit::Menu::Hub
    def setup_hub
      menu_hub(:setup, "🥷", hub_path(:setup), hub_landing(:setup), parent: :profile, pages: [
        menu_page(:categories, categories_path, %w[categories]),
        menu_page(:product_types, product_types_path, %w[product_types]),
        menu_page(:people, people_path, %w[people]),
        menu_page(:groups, groups_path, %w[groups]),
        *administrator_pages
      ])
    end

    #: () -> Array[Appkit::Menu::Page]
    def administrator_pages
      return [] unless Current.user&.administrator?

      [
        menu_page(:users, admin_users_path, %w[admin/users]),
        menu_page(:admin_dashboard, admin_root_path, %w[admin/dashboard])
      ]
    end

    #: (Symbol) -> Hash[String, String]
    def hub_landing(key)
      { "controller" => "hubs", "id" => key.to_s }
    end

    #: (Symbol, String, String, Hash[String, String], **untyped) -> Appkit::Menu::Hub
    def menu_hub(key, emoji, path, landing, **options)
      Appkit::Menu::Hub.new(
        key: key, label: t("menu.hubs.#{key}.label"), emoji: emoji, path: path, landing: landing, **options
      )
    end

    #: (Symbol, String, Array[String], **untyped) -> Appkit::Menu::Page
    def menu_page(key, path, controllers, **options)
      Appkit::Menu::Page.new(key: key, label: t("menu.pages.#{key}.label"), path: path, controllers: controllers,
        **options)
    end

    #: (String, String) -> Appkit::Menu::Link
    def menu_link(label, path)
      Appkit::Menu::Link.new(label: label, path: path)
    end

    #: () -> String
    def budget_summary_text
      summary = Dashboard.new.budget_summary
      return t("menu.pages.budgets.no_active_budget") unless summary

      t("menu.pages.budgets.summary", spent: helpers.cents_to_currency(summary.spent),
        planned: helpers.cents_to_currency(summary.planned), left: helpers.cents_to_currency(summary.left))
    end
end
