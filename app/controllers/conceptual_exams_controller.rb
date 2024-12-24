class ConceptualExamsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_classroom
  before_action :require_current_teacher
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy]
  before_action :allow_teacher_modify_prev_years, only: [:create, :update]
  before_action :view_data, only: [:edit, :show]

  def index
    step_id = (params[:filter] || []).delete(:by_step)
    status = (params[:filter] || []).delete(:by_status)

    set_options_by_user

    @conceptual_exams = fetch_conceptual_exams

    check_status_and_step(step_id, status)

    authorize @conceptual_exams
  end

  def new
    set_options_by_user
    discipline_score_types = (teacher_differentiated_discipline_score_types + teacher_discipline_score_types).uniq

    not_concept_score = discipline_score_types.none? do |discipline_score_type|
      [ScoreTypes::CONCEPT, ScoreTypes::NUMERIC_AND_CONCEPT].include?(discipline_score_type)
    end

    if not_concept_score
      if current_user.current_role_is_admin_or_employee?
        redirect_to(
          conceptual_exams_path,
          alert: t('conceptual_exams.new.current_discipline_does_not_have_conceptual_exam')
        ) && return
      end

      flash.now[:alert] = t('conceptual_exams.new.current_discipline_does_not_have_conceptual_exam')
    end

    return if performed?

    @conceptual_exam = ConceptualExam.new(
      unity_id: current_unity.id,
      classroom_id: current_user_classroom.id,
      recorded_at: Date.current
    ).localized

    @conceptual_exam.assign_attributes(resource_params) if params[:conceptual_exam].present?

    authorize @conceptual_exam

    fetch_collections

    (@disciplines || []).each do |discipline|
      @conceptual_exam.conceptual_exam_values.build(
        conceptual_exam: @conceptual_exam,
        discipline: discipline
      )
    end

    mark_exempted_disciplines if @conceptual_exam.conceptual_exam_values.any?
  end

  def create
    begin
      set_options_by_user
      @conceptual_exam = find_or_initialize_conceptual_exam

      authorize @conceptual_exam

      @conceptual_exam.assign_attributes(resource_params)
      @conceptual_exam.merge_conceptual_exam_values
      @conceptual_exam.step_number = @conceptual_exam.step.try(:step_number)
      @conceptual_exam.teacher_id = current_teacher_id
      @conceptual_exam.current_user = current_user

      render :new and return unless @conceptual_exam.save
      respond_to_save
    rescue ActiveRecord::RecordNotUnique
      retry
    end
    return if performed?

    fetch_collections
    mark_not_existing_disciplines_as_invisible
    render :new
  end

  def update
    set_options_by_user
    @conceptual_exam = ConceptualExam.find(params[:id])
    @conceptual_exam.assign_attributes(resource_params)
    @conceptual_exam.teacher_id = current_teacher_id
    @conceptual_exam.current_user = current_user

    authorize @conceptual_exam

    if @conceptual_exam.save
      respond_to_save
    else
      set_options_by_user
      fetch_collections
      mark_not_existing_disciplines_as_invisible
      mark_persisted_disciplines_as_invisible if @conceptual_exam.conceptual_exam_values.any? { |value| value.new_record? }

      render :edit
    end
  end

  def destroy
    @conceptual_exam = ConceptualExam.find(params[:id]).localized
    @conceptual_exam.unity_id = @conceptual_exam.classroom.unity_id
    @classroom = @conceptual_exam.classroom
    @conceptual_exam.step_id = find_step_id
    @conceptual_exam.validation_type = :destroy

    allow_teacher_modify_prev_years

    authorize @conceptual_exam

    if @conceptual_exam.valid?
      ConceptualExamValue.by_conceptual_exam_id(@conceptual_exam.id)
        .destroy_all

      @conceptual_exam.destroy unless ConceptualExamValue.by_conceptual_exam_id(@conceptual_exam.id).any?
    end

    respond_with @conceptual_exam, location: conceptual_exams_path
  end

  def history
    @conceptual_exam = ConceptualExam.find(params[:id]).localized

    authorize @conceptual_exam

    respond_with @conceptual_exam
  end

  def exempted_disciplines
    classroom = Classroom.find(params[:classroom_id])
    step = steps_fetcher(classroom).step_by_id(params[:step_id])
    student_enrollments = student_enrollments(step.start_at, step.end_at, classroom)

    exempted_disciplines = student_enrollments.find do |item|
      item[:student_id] == params[:student_id].to_i
    end.try(:exempted_disciplines)

    if exempted_disciplines
      render json: exempted_disciplines.try(:by_step_number, step.to_number)
    else
      render json: nil, :status => 422
    end
  end

  def find_conceptual_exam_by_student
    render json: find_conceptual_exam.try(:id)
  end

  def find_step_number_by_classroom
    classroom = Classroom.find(params[:classroom_id])
    step_numbers = StepsFetcher.new(classroom)&.steps
    steps = step_numbers.map { |step| { id: step.id, description: step.to_s } }

    render json: steps.to_json
  end

  def fetch_score_type
    return if params[:classroom_id].blank?

    classroom = Classroom.find(params[:classroom_id])

    discipline_score_types = (teacher_differentiated_discipline_score_types(classroom) +
                              teacher_discipline_score_types(classroom)).uniq

    not_concept_score = discipline_score_types.none? do |discipline_score_type|
      discipline_score_type.include?([ScoreTypes::CONCEPT, ScoreTypes::NUMERIC_AND_CONCEPT])
    end

    render json: not_concept_score
  end

  def fetch_period
    return if params[:classroom_id].blank?

    render json: TeacherPeriodFetcher.new(
      current_teacher.id,
      params[:classroom_id],
      current_user_discipline
    ).teacher_period
  end

  private

  def view_data
    @conceptual_exam = ConceptualExam.find(params[:id]).localized
    @conceptual_exam.unity_id = @conceptual_exam.classroom.unity_id
    @classroom = @conceptual_exam.classroom
    @conceptual_exam.step_id = find_step_id

    authorize @conceptual_exam
    set_options_by_user
    fetch_collections
    add_missing_disciplines
    mark_not_assigned_disciplines_for_destruction
    mark_not_existing_disciplines_as_invisible
    mark_exempted_disciplines
  end

  def resource_params
    params.require(:conceptual_exam).permit(
      :unity_id,
      :classroom_id,
      :recorded_at,
      :student_id,
      :step_id,
      conceptual_exam_values_attributes: [
        :id,
        :discipline_id,
        :value,
        :exempted_discipline,
        :_destroy
      ]
    )
  end

  def find_step_id
    steps_fetcher(@classroom).step(@conceptual_exam.step_number).try(:id)
  end

  def find_conceptual_exam
    classroom = Classroom.find(resource_params[:classroom_id])

    ConceptualExam.by_classroom(resource_params[:classroom_id])
      .by_student_id(resource_params[:student_id])
      .by_step_id(classroom, resource_params[:step_id])
      .first
  end

  def find_or_initialize_conceptual_exam
    conceptual_exam = find_conceptual_exam

    if conceptual_exam.blank?
      conceptual_exam = ConceptualExam.new(
        classroom_id: resource_params[:classroom_id],
        student_id: resource_params[:student_id],
        recorded_at: resource_params[:recorded_at],
        step_id: resource_params[:step_id]
      )
    end

    conceptual_exam
  end

  def add_missing_disciplines
    missing_disciplines.each do |missing_discipline|
      @conceptual_exam.conceptual_exam_values.build(
        conceptual_exam: @conceptual_exam,
        discipline: missing_discipline
      )
    end
  end

  def missing_disciplines
    missing_disciplines = []

    grades = @classrooms.first.grades
    current_step = [@conceptual_exam.step_number].to_s

    disciplines_in_grade_ids = SchoolCalendarDisciplineGrade.where(
      school_calendar: current_school_calendar,
      grade: grades
    ).pluck(:discipline_id, :steps).flat_map do |discipline_id, steps|
      discipline_id if steps.nil? || steps.include?([current_step].to_s)
    end.compact

    filter_discipline = @disciplines.select { |d| d.id.in?(disciplines_in_grade_ids) }

    (filter_discipline || []).each do |discipline|
      is_missing = @conceptual_exam.conceptual_exam_values.none? do |conceptual_exam_value|
        conceptual_exam_value.discipline.id == discipline.id
      end

      missing_disciplines << discipline if is_missing
    end

    missing_disciplines
  end

  def mark_not_assigned_disciplines_for_destruction
    @conceptual_exam.conceptual_exam_values.where.not(discipline_id: disciplines_with_assignment).each do |conceptual_exam_value|
      conceptual_exam_value.mark_for_destruction
    end
  end

  def mark_not_existing_disciplines_as_invisible
    return if @disciplines.blank?

    @conceptual_exam.conceptual_exam_values.each do |conceptual_exam_value|
      discipline_exists = @disciplines.any? do |discipline|
        conceptual_exam_value.discipline.id == discipline.id
      end

      conceptual_exam_value.mark_as_invisible unless discipline_exists
    end
  end

  def mark_persisted_disciplines_as_invisible
    return if @disciplines.blank?

    @conceptual_exam.conceptual_exam_values.each do |conceptual_exam_value|
      discipline_exists = @disciplines.any? do |discipline|
        conceptual_exam_value.new_record?
      end

      conceptual_exam_value.mark_as_invisible unless discipline_exists
    end
  end

  def mark_exempted_disciplines
    return if @conceptual_exam.recorded_at.blank? || @conceptual_exam.step.blank?

    @student_enrollments ||= student_enrollments(
      @conceptual_exam.step.start_at,
      @conceptual_exam.step.end_at,
      @conceptual_exam.classroom,
      @conceptual_exam.discipline
    )

    if current_student_enrollment = @student_enrollments.find { |item| item[:student_id] == @conceptual_exam.student_id }
      exempted_disciplines = current_student_enrollment.exempted_disciplines

      @conceptual_exam.conceptual_exam_values.each do |conceptual_exam_value|
        conceptual_exam_value.exempted_discipline = student_exempted_from_discipline?(conceptual_exam_value.discipline_id, exempted_disciplines)
      end
    end
  end

  def disciplines_with_assignment
    TeacherDisciplineClassroom.by_classroom(@conceptual_exam.classroom_id)
      .by_year(current_school_calendar.year)
      .pluck(:discipline_id)
      .uniq
  end

  def fetch_collections
    if @conceptual_exam.step_id.present? && @conceptual_exam.student_id.present?
      fetch_unities_classrooms_disciplines_by_teacher
      fetch_students
    end
  end

  def fetch_unities_classrooms_disciplines_by_teacher
    return if @conceptual_exam.recorded_at.blank?

    fetcher = UnitiesClassroomsDisciplinesByTeacher.new(
      current_teacher.id,
      @conceptual_exam.classroom.unity_id,
      @conceptual_exam.classroom_id
    )
    fetcher.fetch!

    @disciplines = fetcher.disciplines
    @disciplines = @disciplines.by_score_type(ScoreTypes::CONCEPT, @conceptual_exam.try(:student_id)) if @disciplines.present?

    exempted_discipline_ids = ExemptedDisciplinesInStep.discipline_ids(
      @conceptual_exam.classroom_id,
      @conceptual_exam.step_number
    )

    @disciplines = @disciplines.not_grouper
      .where.not(id: exempted_discipline_ids)
      .where(id: disciplines_in_grade)
  end

  def disciplines_in_grade
    school_calendar = @conceptual_exam.school_calendar

    SchoolCalendarDisciplineGrade.where(
      school_calendar_id: school_calendar.id,
      grade_id: student_grade_id
    ).pluck(:discipline_id)
  end

  def student_grade_id
    ClassroomsGrade.by_student_id(@conceptual_exam.student_id)
      .by_classroom_id(@conceptual_exam.classroom_id)
      .first
      .grade_id
  end

  def steps_fetcher(classroom)
    @steps_fetcher ||= StepsFetcher.new(classroom)
  end

  def student_enrollments(start_at, end_at, classroom = nil, discipline = current_user_discipline)
    classroom ||= @conceptual_exam.classroom
    @period = current_teacher_period(classroom) != Periods::FULL.to_i ? current_teacher_period(classroom) : nil

    StudentEnrollmentsList.new(
      classroom: classroom,
      discipline: discipline,
      start_at: start_at,
      end_at: end_at,
      score_type: StudentEnrollmentScoreTypeFilters::CONCEPT,
      search_type: :by_date_range,
      period: @period
    ).student_enrollments
  end

  def fetch_students
    @students = []

    if @conceptual_exam.classroom.present? && @conceptual_exam.recorded_at.present? && @conceptual_exam.step.present?
      @student_enrollments ||= student_enrollments(
        @conceptual_exam.step.start_at,
        @conceptual_exam.step.end_at,
        @conceptual_exam.classroom
      )

      if @conceptual_exam.student_id.present? &&
          @student_enrollments.find { |enrollment| enrollment[:student_id] == @conceptual_exam.student_id }.blank?
        @student_enrollments << StudentEnrollment.by_student(@conceptual_exam.student_id).first
      end

      @student_ids = @student_enrollments.collect(&:student_id)

      @students = Student.where(id: @student_ids).ordered
    end
  end

  def respond_to_save
    if params[:commit] == 'Salvar'
      respond_with @conceptual_exam, location: conceptual_exams_path
    else
      respond_with_next_conceptual_exam
    end
  end

  def respond_with_next_conceptual_exam
    next_conceptual_exam = fetch_next_conceptual_exam

    if next_conceptual_exam.present?
      if next_conceptual_exam.new_record?
        respond_with(
          @conceptual_exam,
          location: new_conceptual_exam_path(
            conceptual_exam: next_conceptual_exam.attributes.merge(step_id: @conceptual_exam.step_id)
          )
        )
      else
        respond_with(
          @conceptual_exam,
          location: edit_conceptual_exam_path(next_conceptual_exam)
        )
      end
    else
      respond_with(
        @conceptual_exam,
        location: new_conceptual_exam_path
      )
    end
  end

  def fetch_next_conceptual_exam
    next_student = fetch_next_student

    if next_student.present?
      next_conceptual_exam = ConceptualExam.find_or_initialize_by(
        classroom_id: @conceptual_exam.classroom_id,
        student_id: next_student.id,
        recorded_at: @conceptual_exam.recorded_at
      )
    end
  end

  def fetch_next_student
    @students = fetch_students

    if @students.present?
      next_student_index = @students.find_index(@conceptual_exam.student) + 1
      next_student_index = 0 if next_student_index == @students.length

      @students[next_student_index]
    end
  end

  def old_values
    return {} unless @conceptual_exam.classroom.present? && @conceptual_exam.student.present? && @conceptual_exam.step.present?

    @old_values ||= OldStepsConceptualValuesFetcher.new(@conceptual_exam.classroom, @conceptual_exam.student, @conceptual_exam.step).fetch
  end
  helper_method :old_values

  def student_exempted_from_discipline?(discipline_id, exempted_disciplines)
    exempted_disciplines.by_discipline(discipline_id)
      .by_step_number(@conceptual_exam.step_number)
      .any?
  end

  def current_teacher_period(classroom = nil)
    classroom ||= @conceptual_exam.classroom

    TeacherPeriodFetcher.new(
      current_teacher.id,
      classroom.id,
      current_user.current_discipline_id
    ).teacher_period
  end

  def set_options_by_user
    if current_user.current_role_is_admin_or_employee?
      @classrooms ||= [current_user_classroom]
      @disciplines ||= [current_user_discipline]
    else
      fetch_linked_by_teacher
    end
  end

  def check_status_and_step(step_id, status)
    if step_id.present?
      @conceptual_exams = @conceptual_exams.by_step_id(@classrooms, step_id)
      params[:filter][:by_step] = step_id
    end

    if status.present?
      @conceptual_exams = @conceptual_exams.by_status(@classrooms.to_a, current_teacher_id, status)
      params[:filter][:by_status] = status
    end
  end

  def fetch_conceptual_exams
    apply_scopes(ConceptualExam).includes(:student, :classroom)
      .by_unity(current_unity)
      .by_classroom(@classrooms.map(&:id))
      .by_teacher(current_teacher_id)
      .ordered_by_date_and_student
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    @classrooms = @fetch_linked_by_teacher[:classrooms].by_score_type([ScoreTypes::CONCEPT, ScoreTypes::NUMERIC_AND_CONCEPT])
    @disciplines = @fetch_linked_by_teacher[:disciplines].by_score_type(ScoreTypes::CONCEPT)
  end

  def allow_teacher_modify_prev_years
    return if current_user.current_role_is_admin_or_employee?

    @classroom ||= Classroom.find(params[:conceptual_exam][:classroom_id])
    start_date = current_year_steps.first.start_date_for_posting
    end_date = current_year_steps.last.end_date_for_posting

    return if (start_date..end_date).to_a.include?(Date.current)

    flash[:alert] = t('errors.general.not_allowed_to_modify_prev_years')
    redirect_to root_path
  end

  def current_year_steps
    @current_year_steps ||= begin
                              steps = steps_fetcher(@classroom).steps if @classroom.present?
                              year = current_school_year || current_school_calendar.year
                              steps ||= SchoolCalendar.find_by(unity_id: current_unity.id, year: year).steps
                              steps
                            end
  end
end
