class LessonsBoardsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    filters = filter_resolver.resolve

    assign_filters(filters)

    @lessons_boards = apply_scopes(fetcher.lesson_boards)
                      .filter_from_params(filters.to_filter_params)
                      .preload(classrooms_grade: [:grade, { classroom: :unity }])
                      .order('classrooms.description', 'lessons_boards.id')

    authorize @lessons_boards
  end

  def show
    @lessons_board = resource
    @teachers = teachers_to_select2(resource.classroom.id, resource.period, resource.grade_id)

    ActiveRecord::Associations::Preloader.new.preload(
      @lessons_board,
      lessons_board_lessons: :lessons_board_lesson_weekdays
    )

    validate_lessons_number

    authorize @lessons_board
  end

  def new
    unities

    authorize resource
  end

  def create
    resource.assign_attributes(resource_params.to_h)

    authorize resource

    if resource.save
      respond_with resource, location: lessons_boards_path
    else
      render :new
    end
  end

  def edit
    @lessons_board = resource
    @teachers = teachers_to_select2(resource.classroom.id, resource.period, resource.grade_id)
    @classroom = resource.classroom
    validate_lessons_number

    authorize @lessons_board
  end

  def update
    resource.assign_attributes(resource_params.to_h)

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

  def generate_lesson_board_pdf
    @lesson_board = LessonsBoard.find(params[:id])
    html_content = render_to_string(
      action: :generate_lesson_board_pdf, layout: "pdf_lesson_board", formats: [:html]
    )
    response = ReportGenerator.call(html_content)

    send_data response.body,
              filename: "quadro_de_aulas_#{@lesson_board.id}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  def user_role_administrator?
    @role_administrator ||= current_user.reload_current_user_role&.role&.administrator?
  end

  def unities
    @unities ||= fetch_unities
  end

  def fetch_unities
    return [current_user_unity] unless user_role_administrator?

    Unity.joins(:school_calendars)
         .where(school_calendars: { year: current_user_school_year })
         .ordered
  end

  def resource
    @lessons_board ||= case params[:action]
                       when 'edit', 'update', 'show', 'destroy'
                         LessonsBoard.find(params[:id])
                       else
                         LessonsBoard.new
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

    render json: ClassroomsGrade.find_by(
      grade_id: params[:grade_id],
      classroom_id: params[:classroom_id]
    )&.id
  end

  def period
    return if params[:classroom_id].blank?

    render json: Classroom.find(params[:classroom_id])
                          .period
  end

  def number_of_lessons
    return if params[:classroom_id].blank?

    render json: Classroom.find(params[:classroom_id])
                          .number_of_classes
  end

  def teachers_classroom
    return if params[:classroom_id].blank? || params[:grade_id].blank?

    render json: teachers_to_select2(params[:classroom_id], nil, params[:grade_id])
  end

  def teachers_classroom_period
    return if params[:classroom_id].blank? || params[:period].blank? || params[:grade_id].blank?

    render json: teachers_to_select2(params[:classroom_id], params[:period], params[:grade_id])
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

    render json: LessonsBoard.by_classroom(params[:classroom_id])
                             .empty?
  end

  def not_exists_by_classroom_and_grade
    return if params[:classroom_id].blank? || params[:grade_id].blank?

    render json: LessonsBoard.by_classroom(params[:classroom_id])
                              .by_grade(params[:grade_id])
                              .empty?
  end

  def not_exists_by_classroom_and_period
    return if params[:classroom_id].blank?

    render json: LessonsBoard.by_classroom(params[:classroom_id])
                             .by_period(params[:period])
                             .empty?
  end

  def classroom_multi_grade
    return if params[:classroom_id].blank?

    classroom = Classroom.find(params[:classroom_id])
    render json: classroom.multi_grade?
  end

  def teacher_in_other_classroom
    any_blank_param = (
      params[:teacher_discipline_classroom_id].blank? ||
      params[:lesson_number].blank? ||
      params[:weekday].blank? ||
      params[:classroom_id].blank? ||
      params[:period].blank?
    )

    return if any_blank_param

    render json: linked_teacher(params[:teacher_discipline_classroom_id], params[:lesson_number], params[:weekday],
                                params[:classroom_id], params[:period])
  end

  private

  def fetcher
    @fetcher ||= LessonBoardsFetcher.new(current_user)
  end

  def assign_filters(filters)
    @filtering_params = filters.to_form_params
    @unities_options = filters.unity_options
    @grades_options = filters.grade_options
    @classrooms_options = filters.classroom_options

    log_unity_out_of_reach(filters.unity_id_out_of_reach)
  end

  def filter_resolver
    LessonsBoardsFilterResolver.new(
      params[:search],
      fetcher: fetcher,
      default_year: current_user_school_year
    )
  end

  # Escola fora do acesso indica URL adulterada, favorito antigo ou defeito na cascata: registra
  # para o descarte não sumir sem rastro.
  def log_unity_out_of_reach(unity_id)
    return if unity_id.blank?

    Rails.logger.warn(
      "[LessonsBoards#index] escola fora do acesso descartada do filtro: by_unity=#{unity_id.inspect} " \
      "user_id=#{current_user&.id.inspect} user_role_id=#{current_user&.current_user_role_id.inspect}"
    )
  end

  def validate_lessons_number
    classroom_lessons = resource.classroom.number_of_classes
    board_lessons = resource.lessons_board_lessons.size

    return if classroom_lessons == board_lessons || classroom_lessons < board_lessons

    build_new_lessons(classroom_lessons, board_lessons)
  end

  def build_new_lessons(classroom_lessons, board_lessons)
    while classroom_lessons > board_lessons
      last_lesson = resource.lessons_board_lessons.size

      if resource.lessons_board_lessons.build(lesson_number: last_lesson + 1)
        board_lessons += 1
      end
    end
  end

  def service
    @service ||= LessonBoardsService.new
  end

  def linked_teacher(teacher_discipline_classroom_id, lesson_number, weekday, classroom, period)
    service.linked_teacher(teacher_discipline_classroom_id, lesson_number, weekday, classroom, period)
  end

  def teachers_to_select2(classroom_id, period, grade_id)
    service.teachers(classroom_id, period, grade_id)
  end

  def classrooms_to_select2(grade_id, unity_id)
    classrooms_to_select2 = []

    classrooms = Classroom.by_unity(unity_id)
                          .by_year(current_user_school_year)
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

  def grades_by_unity_to_select2(unity_id)
    grades_to_select2 = []
    grades = Grade.includes(:course)
                  .by_unity(unity_id)
                  .by_year(current_school_year)
                  .ordered

    grades.each do |grade|
      grades_to_select2 << OpenStruct.new(
        id: grade.id,
        name: grade.description.to_s,
        text: grade.description.to_s
      )
    end

    grades_to_select2
  end
end
