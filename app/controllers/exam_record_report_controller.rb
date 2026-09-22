class ExamRecordReportController < ApplicationController
  before_action :require_current_classroom
  before_action :require_current_teacher

  def form
    @exam_record_report_form = ExamRecordReportForm.new(
      unity_id: current_unity.id,
      classroom_id: current_user_classroom.id,
      discipline_id: current_user_discipline.id
    )

    set_options_by_user
    fetch_collections
  end

  def report
    @exam_record_report_form = ExamRecordReportForm.new(resource_params.merge(teacher_id: current_teacher.id))
    set_school_calendars

    if @exam_record_report_form.valid?
      exam_record_report = @school_calendar_classroom_steps.any? ? build_by_classroom_steps : build_by_school_steps
      send_pdf(t("routes.exam_record_report"), exam_record_report.render)
    else
      set_options_by_user
      set_school_calendars

      render :form
    end
  end

  def fetch_step
    return if params[:classroom_id].blank?

    classroom = Classroom.find(params[:classroom_id])
    step_numbers = StepsFetcher.new(classroom)&.steps
    steps = step_numbers.map { |step| { id: step.id, description: step.to_s } }

    render json: steps.to_json
  end

  def classrooms
    return render json: { classrooms: [] } if params[:unity_id].blank?

    render json: { classrooms: select2_options(teacher_classrooms(params[:unity_id])) }
  end

  def disciplines
    return render json: { disciplines: [] } if params[:classroom_id].blank?

    render json: { disciplines: select2_options(teacher_disciplines(params[:classroom_id])) }
  end

  private

  def resource_params
    params.require(:exam_record_report_form).permit(:unity_id,
                                                    :classroom_id,
                                                    :discipline_id,
                                                    :school_calendar_step_id,
                                                    :school_calendar_classroom_step_id)
  end

  def build_by_school_steps
    ExamRecordReport.build(
      current_entity_configuration,
      current_teacher,
      current_school_year,
      @exam_record_report_form.step,
      current_test_setting_step(@exam_record_report_form.step),
      @exam_record_report_form.daily_notes,
      @exam_record_report_form.filter_unique_students,
      @exam_record_report_form.complementary_exams,
      @exam_record_report_form.school_term_recoveries,
      @exam_record_report_form.recovery_lowest_notes?,
      @exam_record_report_form.lowest_notes
    )
  end

  def build_by_classroom_steps
    ExamRecordReport.build(
      current_entity_configuration,
      current_teacher,
      current_school_calendar.year,
      @exam_record_report_form.classroom_step,
      current_test_setting_step(@exam_record_report_form.classroom_step),
      @exam_record_report_form.daily_notes_classroom_steps,
      @exam_record_report_form.filter_unique_students,
      @exam_record_report_form.complementary_exams,
      @exam_record_report_form.school_term_recoveries,
      @exam_record_report_form.recovery_lowest_notes?,
      @exam_record_report_form.lowest_notes
    )
  end

  def teacher_unities
    Unity.by_teacher(current_teacher.id).by_year(current_school_year).ordered
  end

  def teacher_classrooms(unity_id)
    Classroom.by_unity_and_teacher(unity_id, current_teacher.id).by_year(current_school_year).ordered
  end

  def teacher_disciplines(classroom_id)
    ExamRecordReportForm.teacher_disciplines(current_teacher.id, classroom_id)
  end

  def select2_options(records)
    records.map { |record| { id: record.id, name: record.to_s, text: record.to_s } }
  end

  def fetch_collections
    @school_calendar_steps = SchoolCalendarStep.where(school_calendar: current_school_calendar).ordered
    @school_calendar_classroom_steps = SchoolCalendarClassroomStep.by_classroom(current_user_classroom.id).ordered
  end

  def set_options_by_user
    # O campo Escola só é editável pelo administrador (view), então só ele recebe a lista
    @unities ||= current_user.admin? ? teacher_unities : [current_user_unity]

    @classrooms = teacher_classrooms(@exam_record_report_form.unity_id)
    @disciplines = teacher_disciplines(@exam_record_report_form.classroom_id)
  end

  def set_school_calendars
    school_calendar = CurrentSchoolCalendarFetcher.new(
      Unity.find(@exam_record_report_form.unity_id),
      Classroom.find(@exam_record_report_form.classroom_id),
      current_school_year
    ).fetch

    @school_calendar_steps = SchoolCalendarStep.where(school_calendar: school_calendar).ordered
    @school_calendar_classroom_steps = SchoolCalendarClassroomStep.by_classroom(@exam_record_report_form.classroom_id).ordered
  end
end
