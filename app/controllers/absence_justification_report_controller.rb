class AbsenceJustificationReportController < ApplicationController
  before_action :require_current_teacher
   

  def form
    @absence_justification_report_form = AbsenceJustificationReportForm.new
    @absence_justification_report_form.unity_id = current_user_unity.id
    @absence_justification_report_form.school_calendar_year = current_user_school_calendar
    @absence_justification_report_form.current_teacher_id = current_teacher
  end

  def report
    @absence_justification_report_form = AbsenceJustificationReportForm.new(resource_params)
    @absence_justification_report_form.unity_id = current_user_unity.id
    @absence_justification_report_form.school_calendar_year = current_user_school_calendar,
    @absence_justification_report_form.current_teacher_id = current_teacher

    if @absence_justification_report_form.valid?
      fetch_absences
      absence_justification_report = AbsenceJustificationReport.build(current_entity_configuration,
                                                                      @absence_justifications,
                                                                      @absence_justification_report_form)
      send_data(absence_justification_report.render, filename: 'registro-de-justificativa-de-faltas.pdf', type: 'application/pdf', disposition: 'inline')
    else
      clear_invalid_dates
      render :form
    end
  end

  private

  def fetch_absences
    if @absence_justification_report_form.frequence_type_by_discipline?
      @absence_justifications = AbsenceJustification.by_teacher(current_teacher)
                                                    .by_unity(current_user_unity.id)
                                                    .by_school_calendar_report(current_user_school_calendar)
                                                    .by_classroom(@absence_justification_report_form.classroom_id)
                                                    .by_discipline_id(@absence_justification_report_form.discipline_id)
                                                    .by_date_report(@absence_justification_report_form.absence_date, @absence_justification_report_form.absence_date_end)
                                                    .order(absence_date: :asc)
    else
      @absence_justifications = AbsenceJustification.by_teacher(current_teacher)
                                                    .by_unity(current_user_unity.id)
                                                    .by_school_calendar_report(current_user_school_calendar)
                                                    .by_classroom(@absence_justification_report_form.classroom_id)
                                                    .by_date_report(@absence_justification_report_form.absence_date, @absence_justification_report_form.absence_date_end)
                                                    .order(absence_date: :asc)
    end
  end

  def resource_params
    params.require(:absence_justification_report_form).permit(:unity,
                                                              :classroom_id,
                                                              :discipline_id,
                                                              :absence_date,
                                                              :absence_date_end,
                                                              :school_calendar_year,
                                                              :current_teacher_id)
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
end
