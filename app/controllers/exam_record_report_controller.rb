class ExamRecordReportController < ApplicationController
  before_action :require_current_teacher
  before_action :require_current_school_calendar
  before_action :require_current_test_setting

  def form
    @exam_record_report_form = ExamRecordReportForm.new
    fetch_collections
  end

  def report
    @exam_record_report_form = ExamRecordReportForm.new(resource_params)

    if @exam_record_report_form.valid?
      exam_record_report = ExamRecordReport.build(current_entity_configuration,
                                                  current_teacher,
                                                  current_school_calendar.year,
                                                  @exam_record_report_form.step,
                                                  current_test_setting,
                                                  @exam_record_report_form.daily_notes,
                                                  @exam_record_report_form.students_enrollments)

      send_data(exam_record_report.render, filename: 'registro-de-avaliacao.pdf', type: 'application/pdf', disposition: 'inline')
    else
      fetch_collections
      render :form
    end
  end

  private

  def fetch_collections
    @school_calendar_steps = SchoolCalendarStep.where(school_calendar: current_school_calendar)
  end

  def resource_params
    params.require(:exam_record_report_form).permit(:unity_id,
                                                    :classroom_id,
                                                    :discipline_id,
                                                    :school_calendar_step_id)
  end
end
