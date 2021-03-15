class AbsenceJustificationReportController < ApplicationController
  before_action :require_current_clasroom
  before_action :require_current_teacher

  def form
    @absence_justification_report_form = AbsenceJustificationReportForm.new
    @absence_justification_report_form.unity_id = current_unity.id
    @absence_justification_report_form.school_calendar_year = current_school_calendar
    @absence_justification_report_form.current_teacher_id = current_teacher
  end

  def report
    @absence_justification_report_form = AbsenceJustificationReportForm.new(resource_params)
    @absence_justification_report_form.unity_id = current_unity.id
    @absence_justification_report_form.school_calendar_year = current_school_calendar
    @absence_justification_report_form.current_teacher_id = current_teacher
    @absence_justification_report_form.user_id = user_id

    if @absence_justification_report_form.valid?
      absence_justification_report = AbsenceJustificationReport.build(
        current_entity_configuration,
        @absence_justification_report_form
      )

      send_pdf(t('routes.absence_justification'), absence_justification_report.render)
    else
      clear_invalid_dates
      render :form
    end
  end

  private

  def resource_params
    params.require(:absence_justification_report_form).permit(
      :unity,
      :classroom_id,
      :discipline_id,
      :absence_date,
      :absence_date_end,
      :school_calendar_year,
      :current_teacher_id,
      :author
    )
  end

  def clear_invalid_dates
    begin
      resource_params[:absence_date].to_date
    rescue ArgumentError
      @absence_justification_report_form.absence_date = ''
    end

    begin
      resource_params[:absence_date_end].to_date
    rescue ArgumentError
      @absence_justification_report_form.absence_date_end = ''
    end
  end

  def user_id
    @user_id ||= UserDiscriminatorService.new(
      current_user,
      current_user.current_role_is_admin_or_employee?
    ).user_id
  end
end
