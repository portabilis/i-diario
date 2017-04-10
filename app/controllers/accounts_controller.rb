class AccountsController < ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user
    @user.has_to_validate_receive_news_fields = true

    if @user.update_with_password(user_params)
      @user.update_rd_lead
      respond_with @user, location: edit_account_path
    else
      render :edit
    end
  end

  protected

  def user_params
    params.require(:user).permit(
      :email, :first_name, :last_name, :login, :phone, :cpf, :password, :password_confirmation,
      :current_password, :authorize_email_and_sms, :receive_news, :receive_news_related_daily_teacher,
      :receive_news_related_***REMOVED***, :receive_news_related_tools_for_parents, :receive_news_related_all_matters
    )
  end
end
