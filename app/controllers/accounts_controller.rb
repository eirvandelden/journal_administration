# Manages account resources
class AccountsController < ApplicationController
  before_action :set_account, only: %i[show edit update destroy]

  # Lists all accounts with pagination
  #
  # @return [void]
  def index
    @pagy, @records = pagy Account.all
  end

  # Displays a single account
  #
  # @return [void]
  def show; end

  # Renders form for creating a new account
  #
  # @return [void]
  def new
    @account = Account.new
  end

  # Renders form for editing an account
  #
  # @return [void]
  def edit; end

  # Creates a new account
  #
  # @return [void]
  def create
    @account = Account.new(account_params)

    respond_to do |format|
      if @account.save
        format.html { redirect_to @account, notice: "Account was successfully created." }
        format.json { render :show, status: :created, location: @account }
      else
        format.html { render :new }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # Updates an account
  #
  # @return [void]
  def update
    respond_to do |format|
      if @account.update(account_params)
        format.html { redirect_to @account, notice: "Account was successfully updated." }
        format.json { render :show, status: :ok, location: @account }
      else
        format.html { render :edit }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # Deletes an account
  #
  # @return [void]
  def destroy
    @account.destroy
    respond_to do |format|
      format.html { redirect_to accounts_url, notice: "Account was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_account
    @account = Account.find(params[:id])
  end

  def account_params
    params.require(:account).permit(:id, :account_number, :name, :owner, :category_id)
  end
end
