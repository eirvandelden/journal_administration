# Manages transaction categories with hierarchical parent-child relationships
class CategoriesController < ApplicationController
  before_action :set_category, only: %i[show edit update destroy]

  # Lists all categories with parent categories included
  #
  # @return [void]
  def index
    @categories = Category.includes(:parent_category).order("parent_category_id, name")
  end

  # Displays a single category
  #
  # @return [void]
  def show; end

  # Renders form for creating a new category
  #
  # @return [void]
  def new
    @category = Category.new
  end

  # Renders form for editing a category
  #
  # @return [void]
  def edit; end

  # Creates a new category
  #
  # @return [void]
  def create
    @category = Category.new(category_params)

    respond_to do |format|
      if @category.save
        format.html { redirect_to @category, notice: "Category was successfully created." }
        format.json { render :show, status: :created, location: @category }
      else
        format.html { render :new }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  # Updates a category
  #
  # @return [void]
  def update
    respond_to do |format|
      if @category.update(category_params)
        format.html { redirect_to @category, notice: "Category was successfully updated." }
        format.json { render :show, status: :ok, location: @category }
      else
        format.html { render :edit }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  # Deletes a category
  #
  # @return [void]
  def destroy
    @category.destroy
    respond_to do |format|
      format.html { redirect_to categories_url, notice: "Category was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(%i[name direction parent_category_id]).tap do |param|
      param["parent_category_id"] = param["parent_category_id"].to_i
    end
  end
end
