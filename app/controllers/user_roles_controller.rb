class UserRolesController < ApplicationController
  def show
    @user_role = UserRole.find_by_id(params[:id])
    render json: @user_role
  end
end
