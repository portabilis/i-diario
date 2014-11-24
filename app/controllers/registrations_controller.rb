class RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!
  layout "registration"

  def new
  end

  def create
    @signup = signup.new(params[:signup])

    if @user = @signup.save
      flash[:notice] = I18n.t('devise.registrations.signed_up')
      sign_in_and_redirect @user
    else
      render params[:mod]
    end
  end

  def edit
  end

  def update
  end

  def parents
    @signup = Signup::Parents.new
  end

  def students
    @signup = Signup::Students.new(params[:signup])

    if params[:signup].present? && @user = @signup.save
      redirect_to new_user_session_path, notice: I18n.t('registrations.students')
    else
      render 'students'
    end
  end

  def employees
    @signup = Signup::Employees.new(params[:signup])

    if params[:signup].present? && @user = @signup.save
      redirect_to new_user_session_path, notice: I18n.t('registrations.students')
    else
      render 'employees'
    end
  end

  protected

  def set_layout
    'devise'
  end

  def signup
    Signup.factory(params[:mod])
  end
end
