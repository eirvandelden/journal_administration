# Manages household chattels (valuable items with warranties and insurance)
class ChattelsController < ApplicationController
  before_action :set_chattel, only: %i[show edit update destroy]

  # Lists chattels organized by warranty status
  #
  # Separates active items into warrantied and out-of-warranty, plus items that have left possession.
  #
  # @action GET
  # @route /chattels
  # @return [void]
  def index
    @warrantied = Chattel.active.warrantied
    @out_of_warranty = Chattel.active.out_of_warranty
    @left = Chattel.left
  end

  # Displays a single chattel
  #
  # @action GET
  # @route /chattels/:id
  # @return [void]
  def show
  end

  # Renders form for creating a new chattel
  #
  # @action GET
  # @route /chattels/new
  # @return [void]
  def new
    @chattel = Chattel.new
  end

  # Renders form for editing a chattel
  #
  # @action GET
  # @route /chattels/:id/edit
  # @return [void]
  def edit
  end

  # Creates a new chattel
  #
  # @action POST
  # @route /chattels
  # @return [void]
  def create
    @chattel = Chattel.new(chattel_params)

    respond_to do |format|
      if @chattel.save
        format.html { redirect_to @chattel, notice: t(".success") }
        format.json { render :show, status: :created, location: @chattel }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @chattel.errors, status: :unprocessable_entity }
      end
    end
  end

  # Updates a chattel
  #
  # @action PATCH
  # @route /chattels/:id
  # @return [void]
  def update
    respond_to do |format|
      if @chattel.update(chattel_params)
        format.html { redirect_to @chattel, notice: t(".success") }
        format.json { render :show, status: :ok, location: @chattel }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @chattel.errors, status: :unprocessable_entity }
      end
    end
  end

  # Deletes a chattel
  #
  # @action DELETE
  # @route /chattels/:id
  # @return [void]
  def destroy
    @chattel.destroy!

    respond_to do |format|
      format.html { redirect_to chattels_path, status: :see_other, notice: t(".success") }
      format.json { head :no_content }
    end
  end

  private
    # Loads the current chattel from the route id.
    #
    # @return [void]
    def set_chattel
      @chattel = Chattel.find(params[:id])
    end

    # Whitelists chattel params from the request payload.
    #
    # @return [ActionController::Parameters]
    def chattel_params
      params.require(:chattel).permit(:name, :kind, :model_number, :serial_number, :purchase_transaction_id, :purchased_at,
:warranty_expires_at, :left_possession_at, :purchase_price, :notes)
    end
end
