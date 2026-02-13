require "csv"

# CSV import operations for transactions
class Transactions::ImportsController < ApplicationController
  # Creates a new transaction import from a CSV file
  #
  # @return [void]
  def create
    csv = imports_params[:csv]

    # Validate file type
    unless csv.content_type.in?(['text/csv', 'text/plain', 'application/vnd.ms-excel'])
      flash[:alert] = "Invalid file type. Please upload a CSV file."
      return redirect_to transactions_path
    end

    # Validate file size
    if csv.size > 5.megabytes
      flash[:alert] = "File too large. Maximum size is 5MB."
      return redirect_to transactions_path
    end

    # Process CSV with error tracking
    failed = 0
    CSV.foreach(csv.tempfile.path, col_sep: ";") do |row|
      Importing::ING::ImportJob.perform_now(row)
    rescue StandardError => e
      Rails.logger.warn "Failed to import row: #{e.message}"
      failed += 1
    end

    flash[:notice] = "Import complete."
    flash[:alert] = "#{failed} transactions failed to import" if failed.positive?

    redirect_to transactions_path
  end

  private

  def imports_params
    params.permit(:csv)
  end
end
