class CategoryGroupsController < ApplicationController
  before_action :set_category_group, only: %i[show edit update destroy]

  # GET /category_groups
  # GET /category_groups.json
  def index
    @category_groups = CategoryGroup.all
  end

  # GET /category_groups/1
  # GET /category_groups/1.json
  def show; end

  # GET /category_groups/new
  def new
    @category_group = CategoryGroup.new
  end

  # GET /category_groups/1/edit
  def edit; end

  # POST /category_groups
  # POST /category_groups.json
  def create
    @category_group = CategoryGroup.new(category_group_params)

    respond_to do |format|
      if @category_group.save
        format.html { redirect_to @category_group, notice: "Category group was successfully created." }
        format.json { render :show, status: :created, location: @category_group }
      else
        format.html { render :new }
        format.json { render json: @category_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /category_groups/1
  # PATCH/PUT /category_groups/1.json
  def update
    respond_to do |format|
      if @category_group.update(category_group_params)
        format.html { redirect_to @category_group, notice: "Category group was successfully updated." }
        format.json { render :show, status: :ok, location: @category_group }
      else
        format.html { render :edit }
        format.json { render json: @category_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /category_groups/1
  # DELETE /category_groups/1.json
  def destroy
    @category_group.destroy
    respond_to do |format|
      format.html { redirect_to category_groups_url, notice: "Category group was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_category_group
    @category_group = CategoryGroup.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def category_group_params
    params.require(:category_group).permit(%i[name categories account_id])
  end
end
