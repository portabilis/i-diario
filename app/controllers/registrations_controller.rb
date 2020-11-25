class RegistrationsController < ApplicationController
  prepend_before_action :verify_recaptcha?, only: :create
  skip_before_action :authenticate_user!
  layout "registration"

  def new
    @signup = Signup.new(params[:signup])
  end

  def create
    Rails.logger.info(
      "LOG: RegistrationsController#create: #{params[:signup].except(:password, :password_confirmation).to_json}"
    ) if params[:signup]
    @signup = Signup.new(params[:signup])

    if @user = @signup.save
      if @user.active?
        flash[:notice] = I18n.t('devise.registrations.signed_up')
        sign_in_and_redirect @user
      else
        respond_with @signup, location: new_user_session_path, notice: I18n.t('registrations.students')
      end
    else
      render :new
    end
  end

  protected

  def set_layout
    'devise'
  end
end
