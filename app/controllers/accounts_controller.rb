class AccountsController < ApplicationController
  before_action :set_account, only: %i[show edit update destroy update_transactions]

  # GET /accounts
  # GET /accounts.json
  def index
    @pagy, @records = pagy Account.all
  end

  # GET /accounts/1
  # GET /accounts/1.json
  def show; end

  # GET /accounts/new
  def new
    @account = Account.new
  end

  # GET /accounts/1/edit
  def edit; end

  # POST /accounts
  # POST /accounts.json
  def create
    @account = Account.new(account_params)

    respond_to do |format|
      if @account.save
        format.html { redirect_to @account, notice: 'Account was successfully created.' }
        format.json { render :show, status: :created, location: @account }
      else
        format.html { render :new }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /accounts/1
  # PATCH/PUT /accounts/1.json
  def update
    respond_to do |format|
      if @account.update(account_params)
        format.html { redirect_to @account, notice: 'Account was successfully updated.' }
        format.json { render :show, status: :ok, location: @account }
      else
        format.html { render :edit }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /accounts/1
  # DELETE /accounts/1.json
  def destroy
    @account.destroy
    respond_to do |format|
      format.html { redirect_to accounts_url, notice: 'Account was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # GET /accounts/1/update_transactions/
  def update_transactions
    return redirect_back fallback_location: accounts_url, alert: 'Account has no category' if @account.category.blank?

    Transaction.where(debitor_account_id: @account, category_id: nil).update_all category_id: @account.category_id
    Transaction.where(creditor_account_id: @account, category_id: nil).update_all category_id: @account.category_id

    flash[:notice] = "Transactions for account #{@account} were updated to have category #{@account.category.name}."
    redirect_back fallback_location: accounts_url
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_account
    @account = Account.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def account_params
    params.require(:account).permit(:id, :account_number, :name, :owner, :category_id)
  end
end
