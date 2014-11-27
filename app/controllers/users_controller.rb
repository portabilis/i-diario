class UsersController < ApplicationController
  def index
    @users = User.ordered
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])

    if @user.update(user_params)
      UserUpdater.update!(@user, current_entity)

      respond_with @user, location: users_path
    else
      render :edit
    end
  end

  def destroy
    @user = User.find(params[:id])

    @user.destroy

    respond_with @user, location: users_path
  end

  def history
    @user = User.find params[:id]

    respond_with @user
  end

  private

  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :phone, :email, :cpf, :login, :status,
      :authorize_email_and_sms, :student_id
    )
  end
end
