class ChattelsController < ApplicationController
  before_action :set_chattel, only: %i[ show edit update destroy ]

  # GET /chattels or /chattels.json
  def index
    @warrantied = Chattel.active.warrantied
    @out_of_warranty = Chattel.active.out_of_warranty 
    @left = Chattel.left
  end

  # GET /chattels/1 or /chattels/1.json
  def show
  end

  # GET /chattels/new
  def new
    @chattel = Chattel.new
  end

  # GET /chattels/1/edit
  def edit
  end

  # POST /chattels or /chattels.json
  def create
    @chattel = Chattel.new(chattel_params)

    respond_to do |format|
      if @chattel.save
        format.html { redirect_to @chattel, notice: "Chattel was successfully created." }
        format.json { render :show, status: :created, location: @chattel }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @chattel.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /chattels/1 or /chattels/1.json
  def update
    respond_to do |format|
      if @chattel.update(chattel_params)
        format.html { redirect_to @chattel, notice: "Chattel was successfully updated." }
        format.json { render :show, status: :ok, location: @chattel }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @chattel.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /chattels/1 or /chattels/1.json
  def destroy
    @chattel.destroy!

    respond_to do |format|
      format.html { redirect_to chattels_path, status: :see_other, notice: "Chattel was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_chattel
      @chattel = Chattel.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def chattel_params
      params.require(:chattel).permit(:name, :kind, :model_number, :serial_number, :purchase_transaction_id, :purchased_at, :warranty_expires_at, :left_possession_at, :purchase_price, :notes)
    end
end
