class LessonsBoardsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @lessons_boards =  apply_scopes(LessonsBoard).includes(:classroom)
                                                 .filter(filtering_params(params[:search]))
                                                 .ordered
    authorize @lessons_boards
  end

  def show
    @lessons_board = resource
    ActiveRecord::Associations::Preloader.new.preload(@lessons_board, [lessons_board_lessons: [:lessons_board_lesson_weekdays]])
    @teachers = teachers_to_select2(resource.classroom_id, resource.period)
    @classrooms = classrooms_to_select2(resource.classroom&.grade&.id, resource.classroom&.unity&.id)

    authorize @lessons_board
  end

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
    @lessons_board = resource
    @teachers = teachers_to_select2(resource.classroom_id, resource.period)
    @classrooms = Classroom.where(unity_id: resource.classroom&.unity&.id)

    authorize @lessons_board
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
    @lessons_board ||= LessonsBoard.ordered
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

  def grades
    @grades = Grade.by_unity(current_unity).by_year(current_school_year).ordered
  end
  helper_method :grades

  def classrooms
    @classrooms = Classroom.by_unity(current_unity).by_year(current_user_school_year).ordered
  end
  helper_method :classrooms

  def resource
    @lessons_board ||= case params[:action]
                       when 'new', 'create'
                         LessonsBoard.new
                       when 'edit', 'update', 'show', 'destroy'
                         LessonsBoard.find(params[:id])
                       end.localized
  end

  def resource_params
    params.require(:lessons_board).permit(:classroom_id, :period,
                                          lessons_board_lessons_attributes: [
                                            :id, :lesson_number, :_destroy,
                                            lessons_board_lesson_weekdays_attributes: [
                                              :id, :weekday, :teacher_discipline_classroom_id, :_destroy
                                            ]
                                          ])
  end

  def period
    return if params[:classroom_id].blank?

    render json: Classroom.find(params[:classroom_id]).period
  end

  def number_of_lessons
    return if params[:classroom_id].blank?

    render json: Classroom.find(params[:classroom_id]).number_of_classes
  end

  def teachers_classroom
    return if params[:classroom_id].blank?

    render json: teachers_to_select2(params[:classroom_id], nil)
  end

  def teachers_classroom_period
    return if params[:classroom_id].blank? || params[:period].blank?

    render json: teachers_to_select2(params[:classroom_id], params[:period])
  end

  def classrooms_filter
    return if params[:grade_id].blank? && params[:unity_id].blank?

    render json: classrooms_to_select2(params[:grade_id], params[:unity_id])
  end

  def grades_by_unity
    return if params[:unity_id].blank?

    render json: grades_by_unity_to_select2(params[:unity_id])
  end

  def not_exists_by_classroom
    return if params[:classroom_id].blank?

    render json: LessonsBoard.find_by(classroom_id: params[:classroom_id]).nil?
  end

  def not_exists_by_classroom_and_period
    return if params[:classroom_id].blank?

    render json: LessonsBoard.find_by(classroom_id: params[:classroom_id], period: params[:period]).nil?
  end

  private

  def teachers_to_select2(classroom_id, period)
    teachers_to_select2 = []
    classroom_period = Classroom.find(classroom_id).period

    if classroom_period == Periods::FULL && period
      TeacherDisciplineClassroom.where(classroom_id: classroom_id, period: period)
                                .includes(:teacher, :discipline).each do |teacher_discipline_classroom|
        teachers_to_select2 << OpenStruct.new(
          id: teacher_discipline_classroom.id,
          name: teacher_discipline_classroom.teacher.name.try(:strip) + ' - ' +
            teacher_discipline_classroom.discipline.description.try(:strip),
          text: teacher_discipline_classroom.teacher.name.try(:strip).to_s + ' - ' +
            teacher_discipline_classroom.discipline.description.try(:strip)
        )
      end
    else
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
    end

    teachers_to_select2
  end

  def classrooms_to_select2(grade_id, unity_id)
    classrooms_to_select2 = []

    Classroom.by_unity(unity_id).by_grade(grade_id).by_year(current_user_school_year).each do |classroom|
      classrooms_to_select2 << OpenStruct.new(
        id: classroom.id,
        name: classroom.description.to_s,
        text: classroom.description.to_s
      )
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
end
