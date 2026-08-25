# Manages the kinds of thing we buy, and how each kind is booked
class ProductTypesController < ApplicationController
  before_action :set_product_type, only: %i[edit update]

  # Lists the product types with the category each is booked to
  #
  # @return [void]
  def index
    @product_types = ProductType.includes(:category).order(:name)
  end

  # Renders the form for a new product type
  #
  # @return [void]
  def new
    @product_type = ProductType.new
  end

  # Renders the form for an existing product type
  #
  # @return [void]
  def edit; end

  # Creates a product type
  #
  # @return [void]
  def create
    @product_type = ProductType.new(product_type_params)

    return redirect_to product_types_path, notice: t(".success") if @product_type.save

    render :new
  end

  # Updates a product type
  #
  # @return [void]
  def update
    return redirect_to product_types_path, notice: t(".success") if @product_type.update(product_type_params)

    render :edit
  end

  private

  def set_product_type
    @product_type = ProductType.find(params[:id])
  end

  def product_type_params
    params.expect(product_type: %i[name category_id])
  end
end
