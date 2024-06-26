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
    # failed = 0

    CSV.foreach(csv.tempfile.path, col_sep: ";") do |row|
      IngSemicolonTransactionJob.perform_now row
    end

    # flash[:alert] = "#{failed} transacties niet geimporteerd" if failed.positive?

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
