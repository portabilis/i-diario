class TeacherReportCardsController < ApplicationController
  before_action :require_current_teacher
  before_action :require_current_classroom

  def form
    @teacher_report_card_form = TeacherReportCardForm.new(
      unity_id: current_unity.id,
      classroom_id: current_user_classroom.id,
      grade_id: current_user_classroom.classrooms_grades.pluck(:grade_id),
      discipline_id: current_user_discipline.id
    )
    @teacher_report_card_form.status = TeacherReportCardStatus::ALL

    set_options_by_user

    authorize(TeacherReportCard, :show?)
  end

  def report
    @teacher_report_card_form = TeacherReportCardForm.new(resource_params)

    authorize(TeacherReportCard, :show?)

    if @teacher_report_card_form.valid?
      teacher_report_card = TeacherReportCard.new(current_configuration)

      unity = Unity.find(@teacher_report_card_form.unity_id)
      discipline = Discipline.find(@teacher_report_card_form.discipline_id)
      classroom = Classroom.find(@teacher_report_card_form.classroom_id)
      grade = Grade.find(@teacher_report_card_form.grade_id)
      course = grade.course
      year = current_user_school_year

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
      set_options_by_user
      render :form
    end
  end

  def set_grades_by_classroom
    return if params[:classroom_id].blank?

    classroom = Classroom.find(params[:classroom_id])

    render json: classroom.grades
  end

  def classrooms_filter
    return if params[:grade_id].blank? && params[:unity_id].blank?

    render json: classrooms_to_select2(params[:grade_id], params[:unity_id])
  end

  def classrooms_to_select2(grade_id, unity_id)
    classrooms_to_select2 = []

    classrooms = Classroom.by_unity(unity_id)
                          .by_year(current_user_school_year)
                          .by_teacher_id(current_teacher.id)
                          .ordered

    classrooms = classrooms.by_grade(grade_id) if grade_id.present?

    classrooms.each do |classroom|
      classrooms_to_select2 << OpenStruct.new(
        id: classroom.id,
        name: classroom.description.to_s,
        text: classroom.description.to_s
      )
    end

    classrooms_to_select2
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
      :unity_id, :classroom_id, :grade_id, :discipline_id, :status
    )
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    classroom_by_grade = current_user_classroom.classrooms_grades.first.grade_id
    classroom_id = @teacher_report_card_form.classroom_id
    @disciplines = @fetch_linked_by_teacher[:disciplines].by_classroom_id(classroom_id).not_descriptor
    @classrooms = @fetch_linked_by_teacher[:classrooms].by_grade(classroom_by_grade)
    @grades = @fetch_linked_by_teacher[:classroom_grades].map(&:grade)
    @unities = [current_user_unity]
  end

  def set_options_by_user
    @admin_or_teacher ||= current_user.current_role_is_admin_or_employee?

    return fetch_options_by_admin if @admin_or_teacher

    fetch_linked_by_teacher
  end

  def fetch_options_by_admin
    @classrooms ||= Classroom.by_unity_id(@teacher_report_card_form.unity_id)
                             .by_grade(@teacher_report_card_form.grade_id)
                             .by_year(current_user_school_year || Date.current.year)
                             .ordered
    @disciplines ||= Discipline.by_classroom_id(@teacher_report_card_form.classroom_id).not_descriptor
    @grades ||= current_user_classroom.classrooms_grades.map(&:grade)
    @unities = Unity.ordered
  end
end
