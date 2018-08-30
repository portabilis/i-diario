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
    fetch_collections

    if @exam_record_report_form.valid?
      exam_record_report = @school_calendar_classroom_steps.any? ? build_by_classroom_steps : build_by_school_steps

      send_data(exam_record_report.render, filename: 'registro-de-avaliacao.pdf', type: 'application/pdf', disposition: 'inline')
    else
      fetch_collections
      render :form
    end
  end

  private

  def build_by_school_steps
    ExamRecordReport.build(current_entity_configuration,
                                                current_teacher,
                                                current_school_calendar.year,
                                                @exam_record_report_form.step,
                                                current_test_setting,
                                                @exam_record_report_form.daily_notes,
                                                @exam_record_report_form.students_enrollments,
                                                @exam_record_report_form.complementary_exams)
  end

  def build_by_classroom_steps
    ExamRecordReport.build(current_entity_configuration,
                                                current_teacher,
                                                current_school_calendar.year,
                                                @exam_record_report_form.classroom_step,
                                                current_test_setting,
                                                @exam_record_report_form.daily_notes_classroom_steps,
                                                @exam_record_report_form.students_enrollments,
                                                @exam_record_report_form.complementary_exams)
  end

  def fetch_collections
    @school_calendar_steps = SchoolCalendarStep.where(school_calendar: current_school_calendar).ordered
    @school_calendar_classroom_steps = SchoolCalendarClassroomStep.by_classroom(current_user_classroom.id).ordered
  end

  def resource_params
    params.require(:exam_record_report_form).permit(:unity_id,
                                                    :classroom_id,
                                                    :discipline_id,
                                                    :school_calendar_step_id,
                                                    :school_calendar_classroom_step_id)
  end
end
