# Shows what we buy and lets a person say what each thing is
class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update]

  # Lists the products, marking the ones still needing classification
  #
  # @return [void]
  def index
    @products = set_page_and_extract_portion_from Product.includes(:product_type).order(:name), per_page: [ 20 ]
  end

  # Displays one product with every purchase of it
  #
  # @return [void]
  def show
    @purchases = @product.purchases
  end

  # Renders the form for classifying a product
  #
  # @return [void]
  def edit
    load_form_choices
  end

  # Records a product's brand and type
  #
  # @return [void]
  def update
    return redirect_to products_path, notice: t(".success") if @product.update(product_params)

    load_form_choices
    render :edit, status: :unprocessable_entity
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def load_form_choices
    @brands_in_use = Product.brands_in_use
    @product_types = ProductType.order(:name)
  end

  def product_params
    params.expect(product: %i[name brand product_type_id])
  end
end
