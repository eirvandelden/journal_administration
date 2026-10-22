# Manages groups of people that can own accounts.
class GroupsController < ApplicationController
  before_action :set_group, only: %i[show edit update destroy]

  # Lists groups.
  # @action GET
  # @route /groups
  # @return [void]
  def index
    @groups = Group.includes(:people).order(:name)
  end

  # Shows a group and its members.
  # @action GET
  # @route /groups/:id
  # @return [void]
  def show; end

  # Renders the form for a new group.
  # @action GET
  # @route /groups/new
  # @return [void]
  def new
    @group = Group.new
  end

  # Renders the form for editing a group.
  # @action GET
  # @route /groups/:id/edit
  # @return [void]
  def edit; end

  # Creates a group.
  # @action POST
  # @route /groups
  # @return [void]
  def create
    @group = Group.new(group_params)
    return redirect_to @group, notice: t("groups.create.success") if @group.save

    render :new, status: :unprocessable_entity
  end

  # Updates a group's name and people.
  # @action PATCH
  # @route /groups/:id
  # @return [void]
  def update
    return redirect_to @group, notice: t("groups.update.success") if @group.update(group_params)

    return render :edit, status: :unprocessable_entity if @group.errors.key?(:name)

    redirect_to @group, alert: @group.errors.full_messages.to_sentence
  end

  # Deletes a group that owns no account.
  # @action DELETE
  # @route /groups/:id
  # @return [void]
  def destroy
    return redirect_to groups_path, notice: t("groups.destroy.success") if @group.destroy

    redirect_to edit_group_path(@group), alert: @group.errors.full_messages.to_sentence
  end

  private

  # Finds the group named in the path.
  # @return [Group]
  def set_group
    @group = Group.find(params[:id])
  end

  # The fields a group may change.
  # @return [ActionController::Parameters]
  def group_params
    params.expect(group: [ :name, { person_ids: [] } ])
  end
end
