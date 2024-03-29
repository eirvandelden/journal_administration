require "csv"

class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[show edit update destroy]

  # GET /transactions
  # GET /transactions.json
  def index
    transactions = Transaction.all
    transactions = transactions.where(category: nil) if params[:filter] == "no_category"

    @pagy, @transactions = pagy transactions.order(interest_at: :desc), items: 20
  end

  # GET /transactions/1
  # GET /transactions/1.json
  def show; end

  # GET /transactions/new
  def new
    @transaction = Transaction.new
  end

  # GET /transactions/1/edit
  def edit; end

  # POST /transactions
  # POST /transactions.json
  def create
    @transaction = Transaction.new(transaction_params)

    respond_to do |format|
      if @transaction.save
        format.html { redirect_to @transaction, notice: "Transaction was successfully created." }
        format.json { render :show, status: :created, location: @transaction }
      else
        format.html { render :new }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /transactions/1
  # PATCH/PUT /transactions/1.json
  def update
    respond_to do |format|
      if @transaction.update(transaction_params)
        format.html { redirect_to @transaction, notice: "Transaction was successfully updated." }
        format.json { render :show, status: :ok, location: @transaction }
      else
        format.html { render :edit }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /transactions/1
  # DELETE /transactions/1.json
  def destroy
    @transaction.destroy
    respond_to do |format|
      format.html { redirect_to transactions_url, notice: "Transaction was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def upload
    csv    = csv_params[:csv]
    failed = 0
    CSV.foreach(csv.tempfile.path, col_sep: ";") do |row|
      next if row[0] == "Datum"

      # Extract all information
      date                            = DateTime.parse row[0]
      initiator_account_name          = row[1] # Note: this can be either OUR account name, or THEIRS
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

      transaction      = Transaction.new amount: amount, booked_at: date, interest_at: date
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
      # next if Transaction.find_by(transaction.attributes.except('interest_at', 'category_id', 'created_at', 'updated_at', 'id')).present?
      transaction.save!
    end

    flash[:alert] = "#{failed} transacties niet geimporteerd" if failed.positive?

    redirect_to transactions_path
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_transaction
      @transaction = Transaction.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def transaction_params
      key = (params.keys & %w[debit credit transfer transaction])[0]
      params.require(key).permit(:id, :debit_account_id, :credit_account_id, :amount, :booked_at, :interest_at,
  :category_id, :note, :type)
    end

    def csv_params
      params.permit(:csv)
    end
end
