# Lets the household set, change and remove what it appropriates per purpose, recipient and year
class AppropriationsController < ApplicationController
  before_action :set_appropriation, only: %i[show edit update destroy]

  # Lists the appropriations of one budget year, this year unless another is chosen.
  #
  # @action GET
  # @route /appropriations
  # @return [void]
  def index
    @year = params.fetch(:year, Date.current.year).to_i
    @appropriations = Appropriation.of_year(@year).order(:purpose, :recipient)
  end

  # Shows one appropriation with the payments and split parts charged to it.
  #
  # @action GET
  # @route /appropriations/:id
  # @return [void]
  def show; end

  # Renders the form for setting a new appropriation.
  #
  # @action GET
  # @route /appropriations/new
  # @return [void]
  def new
    @appropriation = Appropriation.new(budget_year: Date.current.year)
  end

  # Renders the form for changing an appropriation.
  #
  # @action GET
  # @route /appropriations/:id/edit
  # @return [void]
  def edit; end

  # Sets a new appropriation.
  #
  # @action POST
  # @route /appropriations
  # @return [void]
  def create
    @appropriation = Appropriation.new(appropriation_params)

    if @appropriation.save
      redirect_to appropriations_path(year: @appropriation.budget_year), notice: t(".success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  # Changes an appropriation's amount, purpose, recipient or budget year.
  #
  # @action PATCH
  # @route /appropriations/:id
  # @return [void]
  def update
    if @appropriation.update(appropriation_params)
      redirect_to appropriations_path(year: @appropriation.budget_year), notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Removes an appropriation, refusing while anything is charged to it.
  #
  # @action DELETE
  # @route /appropriations/:id
  # @return [void]
  def destroy
    if @appropriation.destroy
      redirect_to appropriations_path(year: @appropriation.budget_year), notice: t(".success")
    else
      redirect_to @appropriation, alert: @appropriation.errors.full_messages.to_sentence
    end
  end

  private

  # Finds the appropriation named in the path
  def set_appropriation
    @appropriation = Appropriation.find(params[:id])
  end

  # The fields a person may set on an appropriation
  def appropriation_params
    params.expect(appropriation: %i[purpose recipient budget_year amount])
  end
end
