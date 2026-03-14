# Aggregates search results across models and navigation pages
#
# Presentation PORO — not persisted. Used by SearchesController to collect
# and expose grouped results for the global search dialog.
class Search
  # A navigation page that can be matched against a search query
  #
  # @!attribute [r] label_key
  #   @return [String] The i18n key for the page label
  # @!attribute [r] path_helper
  #   @return [Symbol] Rails URL helper method name
  # @!attribute [r] model_class
  #   @return [Class, nil] Optional model class used for %{model} interpolation
  Page = Struct.new(:label_key, :path_helper, :model_class, keyword_init: true) do
    # Returns the translated navigation label for this page
    #
    # @return [String]
    def label
      if model_class
        I18n.t(label_key, model: model_class.model_name.human)
      else
        I18n.t(label_key)
      end
    end

    # Returns true when the query matches the label (case-insensitive)
    #
    # @param query [String]
    # @return [Boolean]
    def matches?(query)
      label.downcase.include?(query.downcase)
    end
  end

  PAGES = [
    Page.new(label_key: "home",                 path_helper: :dashboard_index_path),
    Page.new(label_key: "journal",              path_helper: :transactions_path),
    Page.new(label_key: "main_nav.accounts",    path_helper: :accounts_path,    model_class: Account),
    Page.new(label_key: "main_nav.categories",  path_helper: :categories_path,  model_class: Category),
    Page.new(label_key: "main_nav.chattels",    path_helper: :chattels_path,    model_class: Chattel),
    Page.new(label_key: "main_nav.todo",        path_helper: :todo_path,        model_class: Todo)
  ].freeze

  attr_reader :query

  def initialize(query:)
    @query = query.to_s.strip
  end

  # Returns grouped search results, omitting empty groups
  #
  # @return [Hash{Symbol => Array}]
  def results
    @results ||= compute_results
  end

  # Returns true when there is at least one result group
  #
  # @return [Boolean]
  def any_results?
    results.any?
  end

  private

  def compute_results
    return {} if query.blank?

    {
      pages:        matching_pages,
      accounts:     Account.search(query).to_a,
      transactions: Transaction.search(query).to_a,
      chattels:     Chattel.search(query).to_a,
      categories:   Category.search(query).to_a
    }.reject { |_, v| v.empty? }
  end

  def matching_pages
    return [] if query.blank?

    PAGES.select { |page| page.matches?(query) }
  end
end
