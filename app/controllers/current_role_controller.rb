# encoding: utf-8
class CurrentRoleController < ApplicationController
  def set
    current_role_form = CurrentRoleForm.new(resource_params)

    respond_to do |format|
      if current_role_form.save
        flash[:notice] = I18n.t('current_role.set.notice')
        format.json { render json: current_role_form }
      else
        response = current_role_form.errors
        response[:messages] = current_role_form.errors.full_messages
        format.json { render json: response, status: :unprocessable_entity }
      end
    end
  end

  private

  def resource_params
    params.require(:user).permit(
      :id, :current_user_role_id, :teacher_id, :current_unity_id, :current_classroom_id, :current_discipline_id, :assumed_teacher_id,
    )
  end
end
