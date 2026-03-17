# Manages household budgets with per-category spending allocations.
class BudgetsController < ApplicationController
  before_action :set_budget, only: %i[show edit update destroy suggest]

  # Lists all budgets ordered by most recent first.
  #
  # @action GET
  # @route /budgets
  # @return [void]
  def index
    @budgets = Budget.order(starts_at: :desc).includes(:budget_categories)
  end

  # Displays a single budget with its category allocations.
  #
  # @action GET
  # @route /budgets/:id
  # @return [void]
  def show; end

  # Renders the form for creating a new budget.
  #
  # @action GET
  # @route /budgets/new
  # @return [void]
  def new
    @budget = Budget.new
    @budget.budget_categories.build
  end

  # Renders the form for editing an existing budget.
  #
  # @action GET
  # @route /budgets/:id/edit
  # @return [void]
  def edit; end

  # Creates a new budget.
  #
  # @action POST
  # @route /budgets
  # @return [void]
  def create
    @budget = Budget.new(budget_params)

    if @budget.save
      redirect_to @budget, notice: t("budgets.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  # Updates an existing budget.
  #
  # @action PATCH
  # @route /budgets/:id
  # @return [void]
  def update
    if @budget.update(budget_params)
      redirect_to @budget, notice: t("budgets.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Destroys a budget.
  #
  # @action DELETE
  # @route /budgets/:id
  # @return [void]
  def destroy
    @budget.destroy
    redirect_to budgets_url, notice: t("budgets.destroy.success")
  end

  # Populates budget category fields with historically suggested amounts.
  #
  # @action GET
  # @route /budgets/:id/suggest
  # @return [void]
  def suggest
    @budget.apply_suggestions
    render :edit
  end

  private

  def set_budget
    @budget = Budget.find(params[:id])
  end

  def budget_params
    params.require(:budget).permit(
      :starts_at, :ends_at,
      budget_categories_attributes: %i[id category_id amount _destroy]
    )
  end
end
