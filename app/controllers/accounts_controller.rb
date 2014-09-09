class AccountsController < ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update_with_password(user_params)
      respond_with @user, location: edit_account_path
    else
      render :edit
    end
  end

  protected

  def user_params
    params.require(:user).permit(
      :email, :first_name, :last_name, :login, :phone, :cpf, :password, :password_confirmation,
      :current_password, :authorize_email_and_sms
    )
  end
end
