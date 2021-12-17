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

  def available_classrooms
    filters = params.dig(:filter).slice(:by_unity_id, :by_school_year, :by_teacher_id, :by_user_role_id)

    profile = CurrentProfile.new(current_user, filters)

    render json: { classrooms: profile.classrooms_as_json }
  end

  def available_disciplines
    filters = params.dig(:filter).slice(:by_classroom_id, :by_teacher_id)

    profile = CurrentProfile.new(current_user, filters)

    render json: { disciplines: profile.disciplines_as_json }
  end

  def available_school_years
    filters = params.dig(:filter).slice(:by_user_role_id, :by_unity_id)

    profile = CurrentProfile.new(current_user, filters)

    render json: { school_years: profile.school_years_as_json }
  end

  def available_teachers
    filters = params.dig(:filter).slice(:by_unity_id, :by_school_year, :by_classroom_id, :by_user_role_id)
    return render json: { teachers: [] } if filters[:by_classroom_id].empty?

    profile = CurrentProfile.new(current_user, filters)

    render json: { teachers: profile.teachers_as_json }
  end

  def available_unities
    filters = params.dig(:filter).slice(:by_unity_id, :by_user_role_id)

    profile = CurrentProfile.new(current_user, filters)

    render json: { unities: profile.unities_as_json }
  end

  def available_teacher_profiles
    filters = params.dig(:filter).slice(:by_unity_id, :by_school_year)

    profile = CurrentProfile.new(current_user, filters)

    render json: { teacher_profiles: profile.teacher_profiles_as_json }
  end

  private

  def resource_params
    params.require(:user).permit(
      :current_user_role_id, :current_unity_id, :current_classroom_id, :current_discipline_id, :current_teacher_id,
      :current_school_year, :current_knowledge_area_id
    ).merge(current_user: current_user)
  end

  def redirect_to_path(referer)
    ref_route = Rails.application.routes.recognize_path(referer)
    controller = ref_route[:controller]

    action = ALL_ROUTES["#{controller}#index#pt-BR"] ||
             ALL_ROUTES["#{controller}#new#pt-BR"] ||
             ALL_ROUTES["#{controller}#form#pt-BR"]

    redirect_to action || root_path
  rescue ActionController::RoutingError, ActionController::UrlGenerationError
    redirect_to root_path
  end
end
