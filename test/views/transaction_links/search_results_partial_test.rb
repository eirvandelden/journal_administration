require "test_helper"

class TransactionLinksSearchResultsPartialTest < ActiveSupport::TestCase
  test "renders nothing when search has not been performed" do
    html = ApplicationController.render(
      partial: "transaction_links/search_results",
      locals: { transaction: transactions(:debit_grocery), transfers: [], searched: false }
    )

    assert_equal "", html.strip
  end

  test "renders no results message when search is empty" do
    html = ApplicationController.render(
      partial: "transaction_links/search_results",
      locals: { transaction: transactions(:debit_grocery), transfers: [], searched: true }
    )

    assert_match I18n.t("transaction_links.search.no_results"), html
  end
end
