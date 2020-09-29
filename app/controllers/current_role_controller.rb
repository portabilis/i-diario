# encoding: utf-8
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

      path = redirect_to_path(request.referer)

      format.html { redirect_to(path) }
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
    ref_route = route_from_path(referer)
    @retry = true
    @controller = ref_route[:controller]

    path_eval = Rails.application.routes.url_helpers.send("#{@controller}_path")

    route_from_path(path_eval)
  rescue NoMethodError
    root_path
  end

  def route_from_path(path)
    Rails.application.routes.recognize_path(path)
  rescue ActionController::RoutingError
    if @retry
      if (path = fallback_to_new&.values&.first)

        begin
          path = Rails.application.routes.url_helpers.send("#{path}_path")

          retry
        rescue NoMethodError
          root_path
        end
      end
    end

    root_path
  end

  def fallback_to_new
    @retry = false

    all_routes.find do |route|
      route["#{@controller}#new#pt-BR".to_sym]
    end
  end

  def all_routes
    Rails.cache.fetch('Rails.application.routes') do
      Rails.application.routes.routes.named_routes.values.map do |route|
        { "#{route.defaults[:controller]}##{route.defaults[:action]}##{route.defaults[:locale]}": route.name }
      end
    end
  end
end
