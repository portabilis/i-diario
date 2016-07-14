class UserRolesController < ApplicationController
  def show
    @user_role = UserRole.find_by_id(params[:id])

    respond_to do |format|
      if @user_role.present?
        format.json { render json: @user_role }
      else
        format.json { render json: {}, status: :unprocessable_entity }
      end
    end
  end
end
