# Manages transaction resources
class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[show edit update destroy]

  # Lists all transactions with optional type, category, account, and date range filtering
  #
  # @action GET
  # @route /transactions
  # @return [void]
  def index
    transactions = Transaction
      .includes(:transaction_splits)
      .by_type(params[:type])
      .by_category(params[:category_id])
      .by_account(params[:account_id])
      .in_date_range(params[:start_date], params[:end_date])
    transactions = transactions.uncategorized if params[:filter] == "no_category"

    @transactions = set_page_and_extract_portion_from transactions.order(interest_at: :desc), per_page: [20]
  end

  # Displays a single transaction
  #
  # @return [void]
  def show; end

  # Renders form for creating a new transaction
  #
  # @return [void]
  def new
    @transaction = Transaction.new
  end

  # Renders form for editing a transaction
  #
  # @return [void]
  def edit; end

  # Creates a new transaction
  #
  # @return [void]
  def create
    @transaction = Transaction.new(transaction_params)

    respond_to do |format|
      if @transaction.save
        format.html { redirect_to @transaction, notice: t("transactions.create.success") }
        format.json { render :show, status: :created, location: @transaction }
      else
        format.html { render :new }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # Updates a transaction
  #
  # @return [void]
  def update
    respond_to do |format|
      if @transaction.update(transaction_params)
        format.html { redirect_to @transaction, notice: t("transactions.update.success") }
        format.json { render :show, status: :ok, location: @transaction }
      else
        format.html { render :edit }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # Deletes a transaction
  #
  # @return [void]
  def destroy
    @transaction.destroy
    respond_to do |format|
      format.html { redirect_to transactions_url, notice: t("transactions.destroy.success") }
      format.json { head :no_content }
    end
  end

  private

  def set_transaction
    @transaction = Transaction.find(params[:id])
  end

  def transaction_params
    key = (params.keys & %w[debit credit transfer transaction])[0]
    params.require(key).permit(:id, :debit_account_id, :credit_account_id, :amount, :booked_at, :interest_at,
  :category_id, :note, :type, :proof_of_purchase)
  end
end
