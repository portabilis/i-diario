class GeneralConfigurationsController < ApplicationController
  after_action :clear_cache, only: :update

  def edit
    @general_configuration = GeneralConfiguration.current.localized

    authorize @general_configuration
  end

  def update
    @general_configuration = GeneralConfiguration.current
    @general_configuration.attributes = permitted_attributes

    authorize @general_configuration

    if @general_configuration.save
      respond_with @general_configuration, location: edit_general_configurations_path
    else
      render :edit
    end
  end

  def history
    @general_configuration = GeneralConfiguration.current

    authorize @general_configuration

    respond_with @general_configuration
  end

  protected

  def permitted_attributes
    parameters = params.require(:general_configuration).permit(
      :security_level,
      :employees_default_role_id,
      :allows_after_sales_relationship,
      :display_header_on_all_reports_pages,
      :grouped_teacher_profile,
      :max_descriptive_exam_character_count,
      :support_url,
      :copyright_name,
      :show_school_term_recovery_in_exam_record_report,
      :display_daily_activies_log,
      :show_daily_activities_in_knowledge_area_content_record_report,
      :notify_consecutive_or_alternate_absences,
      :max_consecutive_absence_days,
      :max_alternate_absence_days,
      :days_to_consider_alternate_absences,
      :create_users_for_students_when_synchronize,
      :allows_copy_lesson_plans_to_other_grades,
      :type_of_teaching,
      :types_of_teaching,
      :days_to_expire_password,
      :days_to_disable_access,
      :show_inactive_enrollments,
      :show_percentage_on_attendance_record_report,
      :do_not_send_justified_absence,
      :require_daily_activities_record,
      :remove_lesson_plan_objectives,
      :show_experience_fields,
      :allows_copy_experience_fields_in_lesson_plans,
      :group_children_education,
      :allow_class_number_on_content_records
    )

    parameters[:types_of_teaching] = parameters[:types_of_teaching].split(',')
    parameters
  end

  def clear_cache
    Rails.cache.delete("#{current_entity.id}_entity_copyright")
    Rails.cache.delete("#{current_entity.id}_entity_website")
  end
end
