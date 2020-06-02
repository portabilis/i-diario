class TeacherReportCardsController < ApplicationController
  before_action :require_current_teacher

  def form
    @teacher_report_card_form = TeacherReportCardForm.new(unity_id: current_unity.id)
    @teacher_report_card_form.status = TeacherReportCardStatus::ALL
    authorize(TeacherReportCard, :show?)
  end

  def report
    @teacher_report_card_form = TeacherReportCardForm.new(resource_params)

    authorize(TeacherReportCard, :show?)

    if @teacher_report_card_form.valid?

      teacher_report_card = TeacherReportCard.new(current_configuration)

      unity = current_unity
      discipline = Discipline.find(@teacher_report_card_form.discipline_id)
      classroom = Classroom.find(@teacher_report_card_form.classroom_id)
      grade = classroom.grade
      course = grade.course
      year = current_school_calendar.year

      report = teacher_report_card.build({
        unity_id: unity.api_code,
        course_id: course.api_code,
        grade_id: grade.api_code,
        classroom_id: classroom.api_code,
        discipline_id: discipline.api_code,
        ano: year,
        professor: current_teacher.to_s,
        situacao: @teacher_report_card_form.status
      })
      send_pdf(t("routes.teacher_report_cards"), report)
    else
      render :form
    end
  end

  protected

  def unities
    @unities = [current_unity]
  end
  helper_method :unities

  def classrooms
    @classrooms = Classroom.by_unity_and_teacher(current_unity.try(:id), current_teacher.id)
                           .ordered
  end
  helper_method :classrooms

  def disciplines
    @disciplines = []

    if @teacher_report_card_form.classroom_id.present?
      @disciplines = Discipline.by_teacher_and_classroom(
          current_teacher.id, @teacher_report_card_form.classroom_id
        )
        .ordered
    end
    @disciplines
  end
  helper_method :disciplines

  def resource_params
    params.require(:teacher_report_card_form).permit(
      :unity_id, :classroom_id, :discipline_id, :status
    )
  end
end
