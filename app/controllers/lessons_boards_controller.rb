class LessonsBoardsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10
  before_action :require_current_clasroom, if: :require_classroom?
  before_action :require_profile

  def index
    @lessons_boards =  apply_scopes(LessonsBoard).includes(:classroom)
                                                 .all
                                                 .ordered
    authorize @lessons_boards
  end

  def show; end

  def new
    authorize resource
  end

  def create
    resource.assign_attributes resource_params

    authorize resource


    if resource.save
      respond_with resource, location: lessons_boards_path
    else
      render :new
    end
  end

  def edit
    @lesson_board = resource

    authorize @lesson_board
  end

  def update
    resource.assign_attributes resource_params

    authorize resource

    if resource.save
      respond_with resource, location: lessons_boards_path
    else
      render :edit
    end
  end

  def destroy
    authorize resource

    resource.destroy

    respond_with resource, location: lessons_boards_path
  end

  def filtering_params(params)
    params = {} unless params
    params.slice(:by_year,
                 :by_unity,
                 :by_grade,
                 :by_classroom)
  end

  def lessons_boards
    @lessons_boards ||= LessonsBoard.ordered
  end

  def unities
    @unities ||= Unity.joins(:school_calendars)
                      .where(school_calendars: { year: current_user_school_year })
                      .ordered
  end
  helper_method :unities

  def employee_unities
    return unless current_user.employee?

    roles_ids = Role.where(access_level: AccessLevel::EMPLOYEE).pluck(:id)
    unities_ids = UserRole.where(user_id: current_user.id, role_id: roles_ids).pluck(:unity_id)
    @employee_unities ||= Unity.find(unities_ids)
  end
  helper_method :employee_unities

  def classrooms
    @all_classrooms = Classroom.where(year: current_user_school_year).ordered
  end
  helper_method :classrooms

  def grades
    grades_id = []
    grades_id << classrooms.map { |classroom| classroom.grade.id }
    @all_grades = Grade.where(id: grades_id)
  end
  helper_method :grades

  def resource
    @lesson_board ||= case params[:action]
                      when 'new', 'create'
                        LessonsBoard.new
                      when 'edit', 'update', 'destroy'
                        LessonsBoard.find(params[:id])
                      end.localized
  end

  def resource_params
    params.require(:lessons_board).permit(:classroom_id, :period,
                                          lessons_board_lessons_attributes: [
                                            :id, :lesson_number, :_destroy,
                                            lessons_board_lesson_weekdays_attributes: [
                                              :id, :_destroy, :weekday, :teacher_discipline_classroom_id
                                            ]
                                          ])
  end

  def period
    return if params[:classroom_id].blank?

    render json: Classroom.find(params[:classroom_id]).period
  end

  def number_of_classes
    return if params[:classroom_id].blank?

    render json: number_of_classes_to_select_2(params[:classroom_id])
  end

  def teachers_classroom
    return if params[:classroom_id].blank?

    render json: teachers_to_select2(params[:classroom_id])
  end

  def classrooms_filter
    return if params[:grade_id].blank? && params[:unity_id].blank?

    render json: classrooms_by_grade_or_unity_to_select2(params[:grade_id], params[:unity_id])
  end

  def grades_by_unity
    return if params[:unity_id].blank?

    render json: grades_by_unity_to_select2(params[:unity_id])
  end

  private

  def number_of_classes_to_select_2(classroom_id)
    Classroom.find(classroom_id).number_of_classes
  end

  def teachers_to_select2(classroom_id)
    teachers_to_select2 = []

    TeacherDisciplineClassroom.where(classroom_id: classroom_id)
                              .includes(:teacher, :discipline).each do |teacher_discipline_classroom|
      teachers_to_select2 << OpenStruct.new(
        id: teacher_discipline_classroom.id,
        name: teacher_discipline_classroom.teacher.name.try(:strip) + ' - ' +
          teacher_discipline_classroom.discipline.description.try(:strip),
        text: teacher_discipline_classroom.teacher.name.try(:strip).to_s + ' - ' +
          teacher_discipline_classroom.discipline.description.try(:strip)
      )
    end

    teachers_to_select2
  end

  def classrooms_by_grade_or_unity_to_select2(grade_id, unity_id)
    classrooms_to_select2 = []

    if grade_id.blank?
      Classroom.by_unity(unity_id).each do |classroom|
        classrooms_to_select2 << OpenStruct.new(
          id: classroom.id,
          name: classroom.description.to_s,
          text: classroom.description.to_s
        )
      end
    else
      Classroom.by_grade(grade_id).each do |classroom|
        classrooms_to_select2 << OpenStruct.new(
          id: classroom.id,
          name: classroom.description.to_s,
          text: classroom.description.to_s
        )
      end
    end

    classrooms_to_select2
  end

  def grades_by_unity_to_select2(unity_id)
    grades_to_select2 = []

    Grade.includes(:course).by_unity(unity_id).each do |grade|
      grades_to_select2 << OpenStruct.new(
        id: grade.id,
        name: grade.description.to_s,
        text: grade.description.to_s
      )
    end

    grades_to_select2
  end

  def require_profile
    return if current_user.student? || current_user.parent?
    return if current_teacher && current_user.current_user_role

    flash[:alert] = t('errors.publication.require_profile')

    redirect_to root_path
  end

  def require_classroom?
    current_teacher || current_user_is_employee_or_administrator?
  end
end
