class UsersController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @users = apply_scopes(User.filter(filtering_params params[:search]).ordered)

    @search_full_name = params.dig(:search, :full_name)
    @search_by_cpf = params.dig(:search, :by_cpf)
    @search_email = params.dig(:search, :email)
    @search_login = params.dig(:search, :login)
    @search_status = params.dig(:search, :status)

    authorize @users
  end

  def edit
    @user = User.find(params[:id]).localized

    @teachers = Teacher.active.order_by_name

    authorize @user
  end

  def update
    @user = User.find(params[:id])

    authorize @user

    params[:user].delete :password if params[:user][:password].blank?

    if @user.update(user_params)
      UserUpdater.update!(@user, current_entity)

      respond_with @user, location: users_path
    else
      @teachers = Teacher.active.order_by_name
      render :edit
    end
  end

  def profile_picture
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update(profile_picture: params[:profile_picture])
        format.json { render json: { url: @user.profile_picture_url }, status: :ok }
      else
        format.json { render json: @user.errors[:profile_picture], status: :forbidden }
      end
    end
  end

  def destroy
    @user = User.find(params[:id])

    authorize @user

    @user.destroy

    search_params = {
      'search[full_name]': params.dig(:search, :full_name),
      'search[by_cpf]': params.dig(:search, :by_cpf),
      'search[email]': params.dig(:search, :email),
      'search[login]': params.dig(:search, :login),
      'search[status]': params.dig(:search, :status)
    }

    respond_with @user, location: users_path(search_params)
  end

  def history
    @user = User.find params[:id]

    authorize @user

    respond_with @user
  end

  def export_all
    @exported_users = User.ordered.email_ordered

    respond_with @exported_users do |format|
      format.csv { send_data @exported_users.to_csv, filename: "usuarios.csv" }
    end
  end

  def select2_remote
    users = UserDecorator.data_for_select2_remote(params[:description])
    render json: users
  end

  def export_selected
    users_split = params[:ids].split(',')
    @exported_users = User.where(id: users_split).ordered.email_ordered
    respond_with @exported_users do |format|
      format.csv { send_data @exported_users.to_csv, filename: "usuarios.csv" }
    end
  end

  private

  def roles
    return Role.ordered if current_user.has_administrator_access_level? || current_user.admin?

    Role.exclude_administrator_roles.ordered
  end
  helper_method :roles

  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :phone, :email, :cpf, :login, :status,
      :authorize_email_and_sms, :student_id, :teacher_id, :password,
      :expiration_date,
      :user_roles_attributes => [
        :id, :role_id, :unity_id, :_destroy
      ]
    )
  end

  def filtering_params(params)
    if params
      params.slice(:full_name, :by_cpf, :email, :login, :status)
    else
      {}
    end
  end
end
