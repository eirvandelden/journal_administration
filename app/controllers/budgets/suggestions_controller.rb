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
      @budget.apply_suggestions
      render "budgets/edit"
    end

    private

    def set_budget
      @budget = Budget.find(params[:budget_id])
    end
  end
end
