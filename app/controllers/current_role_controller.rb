# encoding: utf-8
class CurrentRoleController < ApplicationController
  def index
    @user_roles = current_user.user_roles
  end

  def set
    raise "a"
    # if current_user.set_current_user_role!(params[:id])
    #   redirect_to root_path, notice: I18n.t('.current_role.set.notice')
    # else
    #   redirect_to root_path, alert: I18n.t('.current_role.set.alert')
    # end
  end
end
