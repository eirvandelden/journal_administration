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
  # Parses date, accounts (both ours and theirs), transaction direction,
  # amount, and description. Resolves counterparty accounts by account number,
  # embedded account reference in description, or merchant name.
  #
  # @param row [Array<String>] A row from the semicolon-delimited CSV file
  # @return [void]
  # @raise [ActiveRecord::RecordInvalid] If the transaction fails validation
  def perform(row)
    return if row[0] == "Datum"

    # Extract all information
    begin
      date = DateTime.parse(row[0])
    rescue ArgumentError
      Rails.logger.warn "Invalid date format in CSV: #{row[0]}"
      return
    end
    initiator_account_name          = determine_name(row[1]) # Note:this can be either OUR account name or THEIRS
    our_account                     = Account.find_or_create_by account_number: row[2]
    their_account                   = Account.find_or_create_by account_number: row[3] if row[3].present?
    code                            = row[4]
    direction                       = row[5]
    _negative                       = (direction == "Af") ? -1 : 1
    amount                          = row[6].tr(",", ".").to_d
    mutation_kind                   = row[7]
    description                     = row[8]
    original_balance_after_mutation = row [9]
    original_tag                    = row[10]

    # Set missing account to spaarpotje
    if their_account.blank?
      our_accounts    = Account.where.not(owner: nil).map(&:account_number).reject(&:blank?)
      matched_account = our_accounts.select { |account| description.include?(account) }
      their_account   = Account.find_by account_number: matched_account if matched_account.present?
    end

    # Find missing account based on account_name
    their_account = Account.find_or_create_by name: initiator_account_name if their_account.blank?

    their_account.update name: initiator_account_name if their_account&.name.blank?

    transaction      = Transaction.new amount:, booked_at: date, interest_at: date
    transaction.note = description + "\n" + code + "\n" + mutation_kind

    # determine type of transaction
    case direction
    when "Af"
      transaction.creditor = our_account
      transaction.debitor  = their_account
      transaction.type     = "Credit"
    when "Bij"
      transaction.debitor  = our_account
      transaction.creditor = their_account
      transaction.type     = "Debit"
    end
    transaction.type = "Transfer" if our_account.owner.present? && their_account.owner.present?

    transaction.category = case transaction.type
    when "Transfer"
                             Category.find_by(name: "Transfer")
    when "Credit"
                             transaction.debitor.category
    when "Debit"
                             transaction.creditor.category
    end

    transaction.original_note                   = description
    transaction.original_balance_after_mutation = original_balance_after_mutation
    transaction.original_tag                    = original_tag

    # Do not import if this transaction has already been imported
    # next if Transaction.find_by(transaction.attributes.except(
    #                             'interest_at', 'category_id', 'created_at', 'updated_at', 'id')).present?
    transaction.save!
  end

  private
    def determine_name(original_name)
      case original_name
      when /AH to go|AH |.*(Albert Heijn|ALBERT HEIJN|AH to go)/
        "Albert Heijn B.V."
      when /Jumbo /
        "Jumbo B.V."
      when /.*(Kruidvat|KRUIDVAT)/
        "Kruidvat B.V."
      else
        original_name
      end
    end
end
