class ConceptualExamsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher
  before_action :require_current_school_calendar

  def index
    @conceptual_exams = apply_scopes(ConceptualExam)
      .includes(
        :school_calendar_classroom_step,
        :school_calendar_step,
        :student,
        :conceptual_exam_values,
        classroom: :unity
      )
      .filter(filtering_params(params[:search]))
      .by_unity(current_user_unity)
      .by_classroom(current_user_classroom)
      .by_teacher(current_teacher_id)
      .ordered

    authorize @conceptual_exams

    fetch_school_calendar_steps
    fetch_school_calendar_classroom_steps
  end

  def new
    redirect_to conceptual_exams_path, alert: "A disciplina selecionada não possui nota conceitual" unless [teacher_differentiated_discipline_score_type, teacher_discipline_score_type].any? {|discipline_score_type| discipline_score_type != DisciplineScoreTypes::NUMERIC }
    @conceptual_exam = ConceptualExam.new(
      unity_id: current_user_unity.id,
      recorded_at: Time.zone.today
    ).localized

    if params[:conceptual_exam].present?
      @conceptual_exam.assign_attributes(resource_params)
    end

    authorize @conceptual_exam

    fetch_collections

    @disciplines.each do |discipline|
      @conceptual_exam.conceptual_exam_values.build(
        conceptual_exam: @conceptual_exam,
        discipline: discipline
      )
    end
  end

  def create
    @conceptual_exam = ConceptualExam.new(resource_params)

    authorize @conceptual_exam

    conceptual_exam = @conceptual_exam

    if @conceptual_exam.save
      respond_to_save
    else
      clear_invalid_dates
      fetch_collections
      mark_not_existing_disciplines_as_invisible

      render :new
    end
  end

  def edit
    @conceptual_exam = ConceptualExam.find(params[:id]).localized
    @conceptual_exam.unity_id = @conceptual_exam.classroom.unity_id

    authorize @conceptual_exam

    fetch_collections

    add_missing_disciplines
    mark_not_assigned_disciplines_for_destruction
    mark_not_existing_disciplines_as_invisible
    mark_exempted_disciplines

    @any_student_exempted_from_discipline = any_student_exempted_from_discipline?
  end

  def update
    @conceptual_exam = ConceptualExam.find(params[:id])
    @conceptual_exam.assign_attributes(resource_params)

    authorize @conceptual_exam

    if @conceptual_exam.save
      respond_to_save
    else
      clear_invalid_dates
      fetch_collections
      mark_not_existing_disciplines_as_invisible
      mark_persisted_disciplines_as_invisible if @conceptual_exam.conceptual_exam_values.any? { |value| value.new_record? }

      render :edit
    end
  end

  def destroy
    @conceptual_exam = ConceptualExam.find(params[:id]).localized

    authorize @conceptual_exam

    current_teacher_disciplines = Discipline.by_teacher_and_classroom(current_teacher.id, current_user_classroom.id)
    values_to_destroy = ConceptualExamValue.where(conceptual_exam_id: @conceptual_exam.id).where(discipline_id: current_teacher_disciplines)

    values_to_destroy.each { |value| value.destroy }

    @conceptual_exam.destroy unless ConceptualExamValue.where(conceptual_exam_id: @conceptual_exam.id).any?

    respond_with @conceptual_exam, location: conceptual_exams_path
  end

  def history
    @conceptual_exam = ConceptualExam.find(params[:id]).localized

    authorize @conceptual_exam

    respond_with @conceptual_exam
  end

  def exempted_disciplines
    step ||= SchoolCalendarClassroomStep.find_by_id(params[:conceptual_exam_school_calendar_classroom_step_id])
    step ||= SchoolCalendarStep.find(params[:conceptual_exam_school_calendar_step_id])
    @student_enrollments ||= student_enrollments(step.start_at, step.end_at)

    exempted_disciplines = @student_enrollments.find do |item|
      item[:student_id] == params[:student_id].to_i
    end.exempted_disciplines

    render json:exempted_disciplines.by_step_number(step.to_number)
  end

  private

  def resource_params
    params.require(:conceptual_exam).permit(
      :unity_id,
      :classroom_id,
      :school_calendar_step_id,
      :school_calendar_classroom_step_id,
      :recorded_at,
      :student_id,
      conceptual_exam_values_attributes: [
        :id,
        :discipline_id,
        :value,
        :exempted_discipline,
        :_destroy
      ]
    )
  end

  def filtering_params(params)
    params = {} unless params
    params.slice(
      :by_classroom,
      :by_student_name,
      :by_school_calendar_step,
      :by_school_calendar_classroom_step,
      :by_status
    )
  end

  def configuration
    @configuration ||= IeducarApiConfiguration.current
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
    @disciplines.each do |discipline|
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
    @conceptual_exam.conceptual_exam_values.each do |conceptual_exam_value|
      discipline_exists = @disciplines.any? do |discipline|
          conceptual_exam_value.discipline.id == discipline.id
      end
      conceptual_exam_value.mark_as_invisible unless discipline_exists
    end
  end

  def mark_persisted_disciplines_as_invisible
    @conceptual_exam.conceptual_exam_values.each do |conceptual_exam_value|
      discipline_exists = @disciplines.any? do |discipline|
          conceptual_exam_value.new_record?
      end
      conceptual_exam_value.mark_as_invisible unless discipline_exists
    end
  end

  def mark_exempted_disciplines
    @student_enrollments ||= student_enrollments(@conceptual_exam.step.start_at, @conceptual_exam.step.end_at)
    exempted_disciplines = @student_enrollments.find { |item| item[:student_id] == @conceptual_exam.student_id }.exempted_disciplines

    @conceptual_exam.conceptual_exam_values.each do |conceptual_exam_value|
      conceptual_exam_value.exempted_discipline = student_exempted_from_discipline?(conceptual_exam_value.discipline_id, exempted_disciplines)
    end
  end

  def disciplines_with_assignment
    disciplines = TeacherDisciplineClassroom
      .by_classroom(@conceptual_exam.classroom_id)
      .by_year(current_school_calendar.year)
      .collect(&:discipline_id)
      .uniq

    disciplines
  end

  def fetch_collections
    fetch_unities_classrooms_disciplines_by_teacher
    fetch_school_calendar_steps
    fetch_students
    fetch_school_calendar_classroom_steps
  end

  def fetch_unities_classrooms_disciplines_by_teacher
    fetcher = UnitiesClassroomsDisciplinesByTeacher.new(
      current_teacher.id,
      @conceptual_exam.try(:classroom).try(:unity_id) || @conceptual_exam.try(:unity_id),
      @conceptual_exam.classroom_id
    )
    fetcher.fetch!

    @disciplines = fetcher.disciplines
    @disciplines = @disciplines.by_score_type(:concept) if @disciplines.present?
    calendar_step_id = @conceptual_exam.school_calendar_step_id
    classroom_step_id = @conceptual_exam.school_calendar_classroom_step_id

    if calendar_step_id || classroom_step_id
      disciplines_by_step_number = ExemptedDisciplinesInStep.new(@conceptual_exam.classroom_id)
      disciplines_by_step = disciplines_by_step_number.discipline_ids_by_classroom_step(classroom_step_id) if classroom_step_id
      disciplines_by_step = disciplines_by_step_number.discipline_ids_by_calendar_step(calendar_step_id) unless disciplines_by_step
      @disciplines = @disciplines.where.not(id: disciplines_by_step)
    end

    @disciplines
  end

  def fetch_school_calendar_steps
    @school_calendar_steps = current_school_calendar.steps
  end

  def fetch_school_calendar_classroom_steps
    @school_calendar_classroom_steps = SchoolCalendarClassroomStep.by_classroom(current_user_classroom.id)
  end

  def student_enrollments(start_at, end_at)
    StudentEnrollmentsList.new(
      classroom: current_user_classroom,
      discipline: current_user_discipline,
      start_at: start_at,
      end_at: end_at,
      score_type: StudentEnrollmentScoreTypeFilters::CONCEPT,
      search_type: :by_date_range
    ).student_enrollments
  end


  def fetch_students
    @students = []

    if @conceptual_exam.classroom.present? && @conceptual_exam.recorded_at.present? && @conceptual_exam.step.present?
      @student_enrollments ||= student_enrollments(@conceptual_exam.step.start_at, @conceptual_exam.step.end_at)
      @student_ids = @student_enrollments.collect(&:student_id)

      @students = Student.where(id: @student_ids)
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

    if !next_conceptual_exam
      respond_with(
        @conceptual_exam,
        location: new_conceptual_exam_path
      )
    else
      if next_conceptual_exam.new_record?
        respond_with(
          @conceptual_exam,
          location: new_conceptual_exam_path(
            conceptual_exam: next_conceptual_exam.attributes
          )
        )
      else
        respond_with(
          @conceptual_exam,
          location: edit_conceptual_exam_path(next_conceptual_exam)
        )
      end
    end
  end

  def fetch_next_conceptual_exam
    fetch_school_calendar_classroom_steps
    next_student = fetch_next_student

    if next_student
      conceptual_exam_with_school_step = ConceptualExam.find_or_initialize_by(
        classroom_id: @conceptual_exam.classroom_id,
        school_calendar_step_id: @conceptual_exam.school_calendar_step_id,
        student_id: next_student.id
      )

      conceptual_exam_with_classroom_step = ConceptualExam.find_or_initialize_by(
        classroom_id: @conceptual_exam.classroom_id,
        school_calendar_classroom_step_id: @conceptual_exam.school_calendar_classroom_step_id,
        student_id: next_student.id
      )

      next_conceptual_exam = @school_calendar_classroom_steps.any? ? conceptual_exam_with_classroom_step : conceptual_exam_with_school_step
      next_conceptual_exam.recorded_at = @conceptual_exam.recorded_at
      next_conceptual_exam
    end

  end

  def fetch_next_student
    @students = fetch_students

    if @students
      next_student_index = @students.find_index(@conceptual_exam.student) + 1

      if next_student_index == @students.length
        next_student_index = 0
      end

      @students[next_student_index]
    end
  end

  def clear_invalid_dates
    begin
      resource_params[:recorded_at].to_date
    rescue ArgumentError
      @conceptual_exam.recorded_at = ''
    end
  end

  def student_exempted_from_discipline?(discipline_id, exempted_disciplines)
    step_number ||= @conceptual_exam.school_calendar_classroom_step.try(:to_number)
    step_number ||= @conceptual_exam.school_calendar_step.to_number

    exempted_disciplines.by_discipline(discipline_id)
                        .by_step_number(step_number)
                        .any?
  end

  def any_student_exempted_from_discipline?
    @conceptual_exam.conceptual_exam_values.any?(&:exempted_discipline)
  end
end
