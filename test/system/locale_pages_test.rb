require "application_system_test_case"
require "i18n/tasks"

class LocalePagesTest < ApplicationSystemTestCase
  PAGES = %i[root_path transactions_path accounts_path categories_path budgets_path
             appropriations_path receipts_path products_path chattels_path].freeze
  CHROME = "nav, h1, h2, h3, label:not(:has(select)), th, button, summary, legend, [type=submit]".freeze

  test "Dutch main pages show no English text" do
    sign_in_as users(:admin)

    assert_pages_in :nl
  end

  test "Italian main pages show no English text" do
    users(:member).update!(locale: :it)
    sign_in_as users(:member)

    assert_pages_in :it
  end

  private

  # Visits every page, refutes .translation_missing and every known English text in the page chrome.
  #: (Symbol locale) -> void
  def assert_pages_in(locale)
    english = known_english_text(locale)

    PAGES.each do |path|
      visit public_send(path)

      assert_no_selector ".translation_missing"
      chrome = page.all(CHROME, minimum: 0).map(&:text).join("\n")

      assert_empty chrome.scan(english).uniq, "#{path} shows English text"
    end
  end

  # Whole-word, case-sensitive pattern of the en values the locale should have translated.
  #: (Symbol locale) -> Regexp
  def known_english_text(locale)
    data = I18n::Tasks::BaseTask.new.data
    translated = data[locale.to_s].key_values.map(&:last)
    english = data["en"].key_values.map(&:last).grep(String) - translated
    words = english.reject { |value| value.include?("%{") }.map { |value| value.sub(/\A[^\p{L}]+/, "").strip }
    patterns = words.grep(/\p{L}/).uniq.map { |word| /(?<!\p{L})#{Regexp.escape(word)}(?!\p{L})/ }
    Regexp.union(patterns)
  end
end
