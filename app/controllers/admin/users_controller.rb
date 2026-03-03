class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [ :show, :edit, :update, :destroy ]

  def index
    @users = set_page_and_extract_portion_from User.order(created_at: :desc), per_page: [ 20 ]
  end

  def show
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(create_user_params)

    if @user.save
      redirect_to admin_user_path(@user), notice: t(".success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(update_user_params)
      redirect_to admin_user_path(@user), notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == Current.user
      redirect_to admin_users_path, alert: t(".cannot_delete_self")
    else
      @user.destroy
      redirect_to admin_users_path, notice: t(".success")
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email_address, :role, :locale, :password, :password_confirmation)
  end

  def create_user_params
    user_params.tap do |permitted|
      permitted[:role] = normalize_role(permitted[:role], fallback: "member")
      permitted[:locale] = normalize_locale(permitted[:locale], fallback: User.new.locale)
    end
  end

  def update_user_params
    user_params.tap do |permitted|
      permitted[:role] = normalize_role(permitted[:role], fallback: @user.role)
      permitted[:locale] = normalize_locale(permitted[:locale], fallback: @user.locale)

      if permitted[:password].blank? && permitted[:password_confirmation].blank?
        permitted.delete(:password)
        permitted.delete(:password_confirmation)
      end
    end
  end

  def normalize_role(role, fallback:)
    role.presence_in(User.roles.keys) || fallback
  end

  def normalize_locale(locale, fallback:)
    locale.presence_in(User.locales.keys) || fallback
  end
end
