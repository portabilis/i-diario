class UsersController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    unless valid_search_params?(params[:search])
      redirect_to root_path, status: 302
      return
    end

    if params[:search]&.dig(:by_name).present?
      params[:search][:by_name] = params[:search][:by_name].squish
    end

    @users = apply_scopes(User.filter_from_params(filtering_params params[:search]).ordered)

    @search_by_name = params.dig(:search, :by_name)
    @search_by_cpf = params.dig(:search, :by_cpf)
    @search_email = params.dig(:search, :email)
    @search_login = params.dig(:search, :login)
    @search_status = params.dig(:search, :status)

    authorize @users
  end

  def edit
    @user = User.find(params[:id]).localized
    @teachers = Teacher.active.order_by_name
    roles

    authorize @user
  end

  def update
    @user = User.find(params[:id])

    authorize @user

    return render :edit unless valid_update

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
      'search[by_name]': params.dig(:search, :by_name),
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
    @roles ||= if current_user.has_administrator_access_level? || current_user.admin?
                list_roles_for_administrator
               else
                Role.exclude_administrator_roles.ordered
               end
  end

  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :phone, :email, :cpf, :login, :status,
      :authorize_email_and_sms, :student_id, :teacher_id, :password, :expiration_date, :admin,
      :user_roles_attributes => [
        :id, :role_id, :unity_id, :_destroy
      ]
    )
  end

  def filtering_params(params)
    if params
      params.slice(:by_name, :by_cpf, :email, :login, :status)
    else
      {}
    end
  end

  def list_roles_for_administrator
    admin_roles = Rails.application.secrets.admin_roles || []

    return Role.ordered if current_user.roles.map(&:name).eql?(admin_roles)

    [Role.exclude_administrator_portabilis.ordered + current_user.roles].flatten
  end

  def not_allow_admin?
    user_not_admin = params[:user][:admin].eql?('0')
    current_user_not_admin = !current_user.admin?

    return false if user_not_admin || current_user_not_admin

    role_ids = params[:user][:user_roles_attributes].values.map do |user_role|
      user_role[:role_id] if user_role[:_destroy].eql?('false')
    end

    Role.where(id: role_ids).pluck(:access_level).exclude?('administrator')
  end

  def valid_update
    password = params[:user][:password]
    params[:user].delete :password if password.blank?

    return true unless not_allow_admin? || weak_password?(password)

    flash.now[:error] = t('users.not_allow_admin') if not_allow_admin?
    flash.now[:error] = t('errors.general.weak_password') if weak_password?(password)

    false
  end

  def valid_search_params?(params_search)
    return true if params_search.blank?

    params_search.values.any?(&:present?)
  end
end
