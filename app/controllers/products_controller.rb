# Shows what we buy and lets a person say what each thing is
class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update]

  # Lists the products, marking the ones still needing classification
  #
  # @return [void]
  def index
    @products = Product.includes(:product_type).order(:name)
  end

  # Displays one product
  #
  # @return [void]
  def show; end

  # Renders the form for classifying a product
  #
  # @return [void]
  def edit
    @brands_in_use = Product.brands_in_use
  end

  # Records a product's brand, type and pack size
  #
  # @return [void]
  def update
    return redirect_to products_path, notice: t(".success") if @product.update(product_params)

    @brands_in_use = Product.brands_in_use
    render :edit
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.expect(product: %i[name brand product_type_id pack_amount pack_unit])
  end
end
