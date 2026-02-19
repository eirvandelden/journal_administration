# Legacy job for importing transactions from ING bank semicolon-delimited CSV
#
# This job handles the original ING CSV format with semicolon delimiters.
# Consider using Importing::ING::ImportJob for new imports as it's more maintainable.
#
# @deprecated Use {Importing::ING::ImportJob} instead
class IngSemicolonTransactionJob < ApplicationJob
  queue_as :default

  # Processes a CSV row from ING bank semicolon-delimited export format
  #
  # Delegates to {Importing::ING::ImportJob} for all processing.
  #
  # @param row [Array<String>] A row from the semicolon-delimited CSV file
  # @return [void]
  # @raise [ActiveRecord::RecordInvalid] If the transaction fails validation
  def perform(row)
    Importing::ING::ImportJob.perform_now(row)
  end
end
