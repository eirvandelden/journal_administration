require "csv"

# CSV import operations for transactions
class Transactions::ImportsController < ApplicationController
  # Creates a new transaction import from a CSV file
  #
  # @return [void]
  def create
    csv = imports_params[:csv]

    # Validate file presence
    if csv.blank?
      flash[:alert] = t('.no_file')
      return redirect_to transactions_path
    end

    # Validate file type
    unless csv.content_type.in?(['text/csv', 'text/plain', 'application/vnd.ms-excel'])
      flash[:alert] = t('.invalid_file_type')
      return redirect_to transactions_path
    end

    # Validate file size
    if csv.size > 5.megabytes
      flash[:alert] = t('.file_too_large')
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

    flash[:notice] = t('.import_complete')
    flash[:alert] = t('.import_failed', count: failed) if failed.positive?

    redirect_to transactions_path
  end

  private

  def imports_params
    params.permit(:csv)
  end
end
