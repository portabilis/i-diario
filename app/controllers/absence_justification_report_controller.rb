class AbsenceJustificationReportController < ApplicationController
  before_action :require_current_classroom
  before_action :require_current_teacher

  def form
    @absence_justification_report_form = AbsenceJustificationReportForm.new(
      classroom_id: current_user_classroom.id,
      unity_id: current_unity.id,
      current_teacher_id: current_teacher.id,
      school_calendar_year: current_school_calendar
    )

    set_options_by_user
  end

  def report
    @absence_justification_report_form = AbsenceJustificationReportForm.new(resource_params)
    @absence_justification_report_form.current_teacher_id = current_teacher
    @absence_justification_report_form.user_id = user_id
    @absence_justification_report_form.school_calendar_year = fetch_school_calendar_by_user

    if @absence_justification_report_form.valid?
      absence_justification_report = AbsenceJustificationReport.build(
        current_entity_configuration,
        @absence_justification_report_form
      )

      send_pdf(t('routes.absence_justification'), absence_justification_report.render)
    else
      set_options_by_user
      clear_invalid_dates
      render :form
    end
  end

  private

  def resource_params
    params.require(:absence_justification_report_form).permit(
      :unity_id,
      :classroom_id,
      :absence_date,
      :absence_date_end,
      :school_calendar_year,
      :current_teacher_id,
      :author
    )
  end

  def clear_invalid_dates
    absence_date = resource_params[:absence_date]
    absence_date_end = resource_params[:absence_date_end]

    @absence_justification_report_form.absence_date = '' unless absence_date.try(:to_date)
    @absence_justification_report_form.absence_date_end = '' unless absence_date_end.try(:to_date)
  end

  def user_id
    @user_id ||= UserDiscriminatorService.new(
      current_user,
      current_user.current_role_is_admin_or_employee?
    ).user_id
  end

  def fetch_school_calendar_by_user
    classroom = Classroom.find_by(id: @absence_justification_report_form.classroom_id)
    unity = Unity.find_by(id: @absence_justification_report_form.unity_id)

    CurrentSchoolCalendarFetcher.new(unity, classroom, current_user_school_year).fetch
  end

  def set_options_by_user
    @admin_or_teacher ||= current_user.current_role_is_admin_or_employee?
    @unities ||= @admin_or_teacher ? Unity.ordered : [current_user_unity]

    return fetch_linked_by_teacher unless current_user.current_role_is_admin_or_employee?

    @classrooms ||= Classroom.by_unity_id(@absence_justification_report_form.unity_id)
                             .by_year(current_user_school_year || Date.current.year)
                             .ordered
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    @classrooms ||= @fetch_linked_by_teacher[:classrooms]
  end
end
