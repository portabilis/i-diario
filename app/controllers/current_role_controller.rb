# encoding: utf-8
class CurrentRoleController < ApplicationController
  def set
    current_role_form =
      if profile_id = params[:user][:teacher_profile_id]
        profile = TeacherProfile.find(profile_id)
        profile_params = {
          teacher_profile_id: profile.id,
          id: profile.user_id,
          current_user_role_id: profile.user_role_id,
          teacher_id: profile.teacher_id,
          current_classroom_id: profile.classroom_id,
          current_discipline_id: profile.discipline_id,
          current_unity_id: profile.unity_id,
          assumed_teacher_id: profile.teacher_id,
          current_school_year: profile.year
        }
        CurrentRoleForm.new(profile_params)
      else
        CurrentRoleForm.new(resource_params)
      end


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
      :id, :current_user_role_id, :teacher_id, :current_unity_id, :current_classroom_id,
      :current_discipline_id, :assumed_teacher_id, :current_school_year, :teacher_profile_id
    )
  end
end
