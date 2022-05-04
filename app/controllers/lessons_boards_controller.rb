class LessonsBoardsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @lessons_boards = LessonBoardsFetcher.new(current_user).lesson_boards
    @lessons_boards = apply_scopes(@lessons_boards).filter(filtering_params(params[:search]))
    authorize @lessons_boards
  end

  def show
    @lessons_board = resource
    ActiveRecord::Associations::Preloader.new.preload(@lessons_board, [lessons_board_lessons: [:lessons_board_lesson_weekdays]])
    @teachers = teachers_to_select2(resource.classroom.id, resource.period)
    @classrooms = classrooms_to_select2(resource.classrooms_grade.grade_id, resource.classroom.unity&.id)

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
    @teachers = teachers_to_select2(resource.classroom.id, resource.period)
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

    resource.discard

    respond_with resource, location: lessons_boards_path
  end

  def filtering_params(params)
    params = {} unless params
    params.slice(:by_year,
                 :by_unity,
                 :by_grade,
                 :by_classroom)
  end

  def lesson_unities
    lessons_unities = []

    if current_user.current_user_role.try(:role_administrator?)
      LessonsBoard.by_unity(unities_id).each { |lesson_board| lessons_unities << lesson_board.classroom.unity.id }
      Unity.where(id: lessons_unities).ordered
    elsif current_user.employee?
      roles_ids = Role.where(access_level: AccessLevel::EMPLOYEE).pluck(:id)
      unities_user = UserRole.where(user_id: current_user.id, role_id: roles_ids).pluck(:unity_id)
      LessonsBoard.by_unity(unities_user).each { |lesson_board| lessons_unities << lesson_board.classroom.unity.id }
      Unity.where(id: lessons_unities).ordered
    end
  end
  helper_method :lesson_unities

  def unities
    if current_user.current_user_role.try(:role_administrator?)
      @unities ||= Unity.joins(:school_calendars)
                        .where(school_calendars: { year: current_user_school_year })
                        .ordered
    else
      [current_user_unity]
    end
  end
  helper_method :unities

  def unities_id
    unities_id = []
    unities.each { |unity| unities_id << unity.id }
    unities_id
  end

  def lesson_grades
    lessons_grades = []
    LessonsBoard.by_unity(unities_id).each { |lesson_board| lessons_grades << lesson_board.classrooms_grade.grade_id }
    Grade.find(lessons_grades)
  end
  helper_method :lesson_grades

  def lesson_classrooms
    lessons_classrooms = []
    LessonsBoard.by_unity(unities_id).each { |lesson_board| lessons_classrooms << lesson_board.classroom.id }
    Classroom.find(lessons_classrooms)
  end
  helper_method :lesson_classrooms

  def resource
    @lessons_board ||= case params[:action]
                       when 'new', 'create'
                         LessonsBoard.new
                       when 'edit', 'update', 'show', 'destroy'
                         LessonsBoard.find(params[:id])
                       end.localized
  end

  def resource_params
    params.require(:lessons_board).permit(:classrooms_grade_id, :period,
                                          lessons_board_lessons_attributes: [
                                            :id, :lesson_number, :_destroy,
                                            lessons_board_lesson_weekdays_attributes: [
                                              :id, :weekday, :teacher_discipline_classroom_id, :_destroy
                                            ]
                                          ])
  end

  def classroom_grade
    return if params[:grade_id].blank? && params[:classroom_id].blank?

    render json: ClassroomsGrade.find_by(grade_id: params[:grade_id], classroom_id: params[:classroom_id])&.id
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

    render json: LessonsBoard.by_classroom(params[:classroom_id]).empty?
  end

  def not_exists_by_classroom_and_period
    return if params[:classroom_id].blank?

    render json: LessonsBoard.by_classroom(params[:classroom_id]).by_period(period: params[:period]).empty?
  end

  def teacher_in_other_classroom
    return if params[:teacher_discipline_classroom_id].blank? ||
              params[:lesson_number].blank? ||
              params[:weekday].blank? ||
              params[:classroom_id].blank?

    render json: linked_teacher(params[:teacher_discipline_classroom_id], params[:lesson_number], params[:weekday], params[:classroom_id])
  end

  private

  def linked_teacher(teacher_discipline_classroom_id, lesson_number, weekday, classroom)
    teacher_discipline_classroom = TeacherDisciplineClassroom.includes(:teacher, classroom: [:unity])
                                                             .find(teacher_discipline_classroom_id)


    teacher_id = teacher_discipline_classroom.teacher.id
    year = teacher_discipline_classroom.classroom.year
    period = teacher_discipline_classroom.classroom.period

    teacher_lessons_board_weekdays = LessonsBoardLessonWeekday.includes(teacher_discipline_classroom:
                                                                          [:teacher, classroom: [:unity]])
                                                              .where(weekday: weekday)
                                                              .joins(lessons_board_lesson: [:lessons_board],
                                                                     teacher_discipline_classroom: [:teacher,
                                                                                                    classroom: [:classrooms_grades]])
                                                              .where(teachers: { id: teacher_id })
                                                              .where(classrooms: { year: year, period: period })
                                                              .where(lessons_board_lessons: { lesson_number:
                                                                                              lesson_number })
                                                              .where.not(classrooms_grades: { classroom_id:
                                                                                             classroom.to_i })
                                                              .first


    return false if teacher_lessons_board_weekdays.nil?

    linked_teacher_message_error(teacher_lessons_board_weekdays.teacher_discipline_classroom.teacher.name,
                                 teacher_lessons_board_weekdays.teacher_discipline_classroom.classroom.description,
                                 teacher_lessons_board_weekdays.teacher_discipline_classroom.classroom.unity,
                                 teacher_lessons_board_weekdays.teacher_discipline_classroom.classroom.year,
                                 Workdays.translate(Workdays.key_for(weekday.to_s)),
                                 lesson_number, teacher_discipline_classroom)
  end

  def linked_teacher_message_error(name, classroom, unity, year, weekday, lesson_number, other_allocation)
    if other_allocation.classroom.unity.id.eql?(unity.id)
      OpenStruct.new(message: "O(a) professor(a) #{name} já está alocado(a) para a turma #{classroom} na mesma escola
      em #{year} na #{weekday} e na #{lesson_number}ª aula. Para conseguir vincular o mesmo, efetue a troca de
      horário em uma das turmas.")
    else
      OpenStruct.new(message: "O(a) professor(a) #{name} já está alocado(a) para a turma #{classroom} na #{unity.name}
      em #{year} na #{weekday} e na #{lesson_number}ª aula. Para conseguir vincular o mesmo, favor contatar o(a)
      responsável da escola para efetuar a troca de horário.")
    end
  end

  def teachers_to_select2(classroom_id, period)
    teachers_to_select2 = []
    classroom_period = Classroom.find(classroom_id).period

    if classroom_period == Periods::FULL && period
      if period != 3
        period = Array([period.to_i, nil])
      end
      TeacherDisciplineClassroom.where(classroom_id: classroom_id, period: period)
                                .joins(:teacher, :discipline)
                                .order('teachers.name')
                                .each do |teacher_discipline_classroom|
        teachers_to_select2 << OpenStruct.new(
          id: teacher_discipline_classroom.id,
          name: discipline_teacher_name(teacher_discipline_classroom.discipline,
                                        teacher_discipline_classroom.teacher.name.try(:strip)),
          text: discipline_teacher_name(teacher_discipline_classroom.discipline,
                                        teacher_discipline_classroom.teacher.name.try(:strip))
        )
      end
    else
      TeacherDisciplineClassroom.where(classroom_id: classroom_id)
                                .includes(:teacher, :discipline)
                                .order('teachers.name')
                                .each do |teacher_discipline_classroom|
        teachers_to_select2 << OpenStruct.new(
          id: teacher_discipline_classroom.id,
          name: discipline_teacher_name(teacher_discipline_classroom.discipline,
                                        teacher_discipline_classroom.teacher.name.try(:strip)),
          text: discipline_teacher_name(teacher_discipline_classroom.discipline,
                                        teacher_discipline_classroom.teacher.name.try(:strip))
        )
      end
    end

    teachers_to_select2.insert(0, OpenStruct.new(id: 'empty', name: '<option></option>', text: ''))

    teachers_to_select2
  end

  def discipline_teacher_name(discipline, teacher)
    "<div class='flex-between'>
       <div class='flex-teacher'>
          <div>
            #{teacher.upcase}
          </div>
       </div>
       <div class='flex-discipline'>
         <span class='flex-discipline-span' style='background-color: #{discipline.label_color};'>#{discipline.description.try(:strip)}</span>
       </div>
     </div>"
  end

  def classrooms_to_select2(grade_id, unity_id)
    classrooms_to_select2 = []

    Classroom.by_unity(unity_id).by_grade(grade_id).by_year(current_user_school_year).ordered.each do |classroom|
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

    Grade.includes(:course).by_unity(unity_id).ordered.each do |grade|
      grades_to_select2 << OpenStruct.new(
        id: grade.id,
        name: grade.description.to_s,
        text: grade.description.to_s
      )
    end

    grades_to_select2
  end
end
