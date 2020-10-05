# encoding: utf-8
class CurrentRoleController < ApplicationController
  ALL_ROUTES = Rails.application.routes.routes.map { |route|
    if route.verb == /^GET$/ && route.defaults[:locale] == 'pt-BR'
      [route.defaults.values.join('#'), route.defaults]
    end
  }.compact.to_h.freeze

  def set
    current_role_form = CurrentRoleForm.new(resource_params)

    respond_to do |format|
      if current_role_form.save
        flash[:notice] = I18n.t('current_role.set.notice')
        format.json { render json: current_role_form }
      else
        format.json { render json: current_role_form.errors, status: :unprocessable_entity }
      end

      format.html do
        redirect_to_path(request.referer)
      end
    end
  end

  private

  def resource_params
    if (profile_id = params[:user][:teacher_profile_id])
      profile = TeacherProfile.find(profile_id)

      return {
        teacher_profile_id: profile.id,
        current_user: current_user,
        current_classroom_id: profile.classroom_id,
        current_discipline_id: profile.discipline_id,
        current_unity_id: profile.unity_id,
        current_teacher_id: profile.teacher_id,
        current_school_year: profile.year
      }
    end

    params.require(:user).permit(
      :current_user_role_id, :current_unity_id, :current_classroom_id, :current_discipline_id, :current_teacher_id,
      :current_school_year, :teacher_profile_id
    ).merge(current_user: current_user)
  end

  def redirect_to_path(referer)
    ref_route = Rails.application.routes.recognize_path(referer)
    controller = ref_route[:controller]

    action = ALL_ROUTES["#{controller}#index#pt-BR"] || ALL_ROUTES["#{controller}#new#pt-BR"]

    redirect_to action || root_path
  rescue ActionController::RoutingError, ActionController::UrlGenerationError
    redirect_to root_path
  end
end
