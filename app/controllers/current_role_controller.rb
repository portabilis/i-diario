class CurrentRoleController < ApplicationController
  def set
    current_role_form = CurrentRoleForm.new(resource_params)

    respond_to do |format|
      if current_role_form.save
        flash[:notice] = I18n.t('current_role.set.notice')
        format.json { render json: current_role_form }
      else
        format.json { render json: current_role_form.errors, status: :unprocessable_entity }
      end
      format.html { redirect_to(root_path) }
    end
  end

  private

  def resource_params
    params.require(:user).permit(
      :current_user_role_id, :current_unity_id, :current_classroom_id, :current_discipline_id, :current_teacher_id,
      :current_school_year, :current_knowledge_area_id
    ).merge(current_user: current_user)
  end
end
