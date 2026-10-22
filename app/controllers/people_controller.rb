# Manages people who can own accounts or receive appropriations.
class PeopleController < ApplicationController
  before_action :set_person, only: %i[show edit update destroy]

  # Lists managed people.
  # @action GET
  # @route /people
  # @return [void]
  def index
    @people = Person.order(:name)
  end

  # Shows a person.
  # @action GET
  # @route /people/:id
  # @return [void]
  def show; end

  # Renders the form for a new person.
  # @action GET
  # @route /people/new
  # @return [void]
  def new
    @person = Person.new
  end

  # Renders the form for editing a person.
  # @action GET
  # @route /people/:id/edit
  # @return [void]
  def edit; end

  # Creates a person.
  # @action POST
  # @route /people
  # @return [void]
  def create
    @person = Person.new(person_params)
    return redirect_to @person, notice: t("people.create.success") if @person.save

    render :new, status: :unprocessable_entity
  end

  # Updates a person.
  # @action PATCH
  # @route /people/:id
  # @return [void]
  def update
    return redirect_to @person, notice: t("people.update.success") if @person.update(person_params)

    return render :edit, status: :unprocessable_entity if @person.errors.key?(:name)

    redirect_to @person, alert: @person.errors.full_messages.to_sentence
  end

  # Deletes an unused person.
  # @action DELETE
  # @route /people/:id
  # @return [void]
  def destroy
    return redirect_to people_path, notice: t("people.destroy.success") if @person.destroy

    redirect_to edit_person_path(@person), alert: @person.errors.full_messages.to_sentence
  end

  private

  # Finds the person named in the path.
  # @return [Person]
  def set_person
    @person = Person.find(params[:id])
  end

  # The fields a person may change.
  # @return [ActionController::Parameters]
  def person_params
    params.expect(person: [ :name, :household ])
  end
end
