class UsersController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @users = apply_scopes(User.filter(filtering_params params[:search]).ordered)

    authorize @users
  end

  def edit
    @user = User.find(params[:id])

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

  def destroy
    @user = User.find(params[:id])

    authorize @user

    @user.destroy

    respond_with @user, location: users_path
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

  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :phone, :email, :cpf, :login, :status,
      :authorize_email_and_sms, :student_id, :teacher_id, :password,
      :user_roles_attributes => [
        :id, :role_id, :unity_id, :_destroy
      ]
    )
  end

  def filtering_params(params)
    if params
      params.slice(:full_name, :email, :login, :status)
    else
      {}
    end
  end
end
