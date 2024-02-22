class PartialScoreRecordReportController < ApplicationController
  def form
    @partial_score_record_report_form = PartialScoreRecordReportForm.new
    @partial_score_record_report_form.classroom_id = current_user.current_classroom_id
    @partial_score_record_report_form.school_calendar_year = current_school_calendar.year
  end

  def report
    @partial_score_record_report_form = PartialScoreRecordReportForm.new(resource_params)
    students_ids = resource_params[:students_ids].presence || students.pluck(:id)
    @partial_score_record_report_form.students_ids = [students_ids].flatten

    if @partial_score_record_report_form.valid?
      current_test_setting_step = current_test_setting_step(@partial_score_record_report_form.step)
      partial_score_record_report = PartialScoreRecordReport.build(current_entity_configuration,
                                                  current_school_calendar.year,
                                                  @partial_score_record_report_form.step,
                                                  @partial_score_record_report_form.students,
                                                  @partial_score_record_report_form.unity,
                                                  @partial_score_record_report_form.classroom,
                                                  current_test_setting_step)

      send_pdf(t("routes.partial_score_record"), partial_score_record_report.render)
    else
      @partial_score_record_report_form.school_calendar_year = current_school_calendar.year
      render :form
    end
  end

  def students_by_daily_note
    classroom_id = params['classroom_id'].presence || @partial_score_record_report_form.classroom_id

    @students_by_daily_note ||= Student.where(
      id: DailyNoteStudent.by_classroom_id(classroom_id)
                          .by_test_date_between(
                            current_school_calendar.first_day,
                            current_school_calendar.last_day
                          )
                          .select(:student_id)
    ).where(
      id: student_ids_with_student_enrollments(classroom_id)
    ).ordered

    respond_with @students_by_daily_note if params['classroom_id'].present?

    @students_by_daily_note
  end

  private

  def student_ids_with_student_enrollments(classroom_id)
    student_enrollments_list = StudentEnrollmentsList.new(
      classroom: classroom_id,
      discipline: current_user.current_discipline_id,
      search_type: :by_year
    )

    student_enrollments_list.student_enrollments.map(&:student_id)
  end

  def school_calendar_steps
    @school_calendar_steps ||= SchoolCalendarStep.where(school_calendar: current_school_calendar)
  end
  helper_method :school_calendar_steps


  def school_calendar_steps_ordered
    school_calendar_steps.ordered
  end
  helper_method :school_calendar_steps_ordered

  def school_calendar_classroom_steps
    @school_calendar_classroom_steps ||= SchoolCalendarClassroomStep.by_classroom(current_user_classroom)
  end
  helper_method :school_calendar_classroom_steps

  def students
    students_by_daily_note
  end
  helper_method :students

  def classrooms
    @classrooms ||= Classroom.by_unity(current_user.current_unity).by_year(current_school_calendar.year).ordered
  end
  helper_method :classrooms

  def resource_params
    params.require(:partial_score_record_report_form).permit(:unity_id,
                                                            :classroom_id,
                                                            :students_ids,
                                                            :school_calendar_step_id,
                                                            :school_calendar_classroom_step_id)
  end
end
