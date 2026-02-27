# Manages transaction resources
class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[show edit update destroy]

  # Lists all transactions with optional category filtering
  #
  # @return [void]
  def index
    transactions = Transaction.ordered
    transactions = transactions.where(category: nil) if params[:filter] == "no_category"

    @pagy, @transactions = pagy transactions.order(interest_at: :desc), items: 20
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
        format.html { redirect_to @transaction, notice: "Transaction was successfully created." }
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
        format.html { redirect_to @transaction, notice: "Transaction was successfully updated." }
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
      format.html { redirect_to transactions_url, notice: "Transaction was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_transaction
    @transaction = Transaction.find(params[:id])
  end

  def transaction_params
    params.require(:transaction).permit(
      :booked_at,
      :interest_at,
      :category_id,
      :note
    )
  end
end
