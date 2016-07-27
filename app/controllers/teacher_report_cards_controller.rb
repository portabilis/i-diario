class TeacherReportCardsController < ApplicationController
  before_action :require_current_teacher

  def form
    @teacher_report_card_form = TeacherReportCardForm.new(unity_id: current_user_unity.id)
    authorize(TeacherReportCard, :show?)
  end

  def report
    @teacher_report_card_form = TeacherReportCardForm.new(resource_params)

    authorize(TeacherReportCard, :show?)

    if @teacher_report_card_form.valid?

      teacher_report_card = TeacherReportCard.new(current_configuration)

      unity = current_user_unity
      discipline = Discipline.find(@teacher_report_card_form.discipline_id)
      classroom = Classroom.find(@teacher_report_card_form.classroom_id)
      grade = classroom.grade
      course = grade.course
      year = Date.today.year

      report = teacher_report_card.build({
        unity_id: unity.api_code,
        course_id: course.api_code,
        grade_id: grade.api_code,
        classroom_id: classroom.api_code,
        discipline_id: discipline.api_code,
        ano: year,
        professor: current_teacher.to_s
      })

      send_data report, type: 'application/pdf', disposition: 'inline', filename: 'boletim.pdf'
    else
      render :form
    end
  end

  protected

  def resource_params
    params.require(:teacher_report_card_form).permit(
      :unity_id, :classroom_id, :discipline_id
    )
  end
end
