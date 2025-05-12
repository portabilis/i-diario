class AccountsController < ApplicationController
  def edit
    @user = current_user
    expired_password?
    user_first_access_messages(@user) if current_user.first_access?
  end

  def update
    @user = current_user
    @user.has_to_validate_receive_news_fields = true

    password = user_params[:password]

    if current_user.first_access? && (user_params[:password].blank? || user_params[:email].include?('ambiente.portabilis.com.br'))
      @user.email = user_params[:email]
      user_first_access_messages(@user)
      render :edit
    elsif weak_password?(password)
      flash.now[:error] = t('errors.general.weak_password')
      render :edit
    else
      @user.update_with_password(user_params)
      respond_with @user, location: edit_account_path
    end
  end

  protected

  def expired_password?
    days_to_expire_password = GeneralConfiguration.current.days_to_expire_password || 0
    return false if current_user.admin? || days_to_expire_password.zero?

    days_after_last_password_change = (Date.current - current_user.last_password_change.to_date).to_i
    return false if days_after_last_password_change <= days_to_expire_password

    @expired_password = true
  end

  def user_first_access_messages(user)
    flash[:error] = 'Atualize os dados do seu perfil, modificando a senha atual para continuar a utilizar o sistema'
    user.errors.add(:password, :must_be_changed)
    user.errors.add(:email, :must_be_changed) if user.email.include?('ambiente.portabilis.com.br')
  end

  def user_params
    params.require(:user).permit(
      :email, :first_name, :last_name, :login, :phone, :cpf, :password, :password_confirmation,
      :current_password, :authorize_email_and_sms, :receive_news, :receive_news_related_daily_teacher,
      :receive_news_related_tools_for_parents, :receive_news_related_all_matters
    )
  end
end
