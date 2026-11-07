# Aggregates search results across models and the menu map's pages
#
# Presentation PORO — not persisted. Used by SearchesController to collect
# and expose grouped results for the global search dialog.
class Search
  attr_reader :query #: String

  #: (query: String?, ?pages: Array[Appkit::Menu::Link]) -> void
  def initialize(query:, pages: [])
    @query = query.to_s.strip
    @pages = pages
  end

  # Returns grouped search results, omitting empty groups
  #
  # @return [Hash{Symbol => Array}]
  #: () -> Hash[Symbol, Array[untyped]]
  def results
    @results ||= compute_results
  end

  # Returns true when there is at least one result group
  #
  # @return [Boolean]
  #: () -> bool
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

    @pages.select { |page| page.label.downcase.include?(query.downcase) }
  end
end
