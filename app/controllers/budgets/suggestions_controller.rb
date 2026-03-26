module Budgets
  # Populates budget category fields with historically suggested amounts.
  class SuggestionsController < ApplicationController
    before_action :set_budget

    # Applies historical suggestions to the budget form and re-renders it.
    #
    # @action POST
    # @route /budgets/:budget_id/suggestion
    # @return [void]
    def create
      render_suggestions
    end

    # Applies historical suggestions to the budget form and re-renders it.
    #
    # @action PATCH
    # @route /budgets/:budget_id/suggestion
    # @return [void]
    def update
      render_suggestions
    end

    private

    def render_suggestions
      @budget.assign_attributes(budget_params) if params[:budget].present?
      @budget.valid?
      @budget.apply_suggestions if @budget.errors[:starts_at].blank? && @budget.errors[:ends_at].blank?
      @budget.valid?
      render "budgets/edit"
    end

    def set_budget
      @budget = Budget.find(params[:budget_id])
    end

    def budget_params
      params.fetch(:budget, {}).permit(
        :starts_at, :ends_at,
        budget_categories_attributes: %i[id category_id amount _destroy]
      )
    end
  end
end
