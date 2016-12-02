class ConceptualExamsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher
  before_action :require_current_school_calendar

  def index
    @conceptual_exams = apply_scopes(ConceptualExam)
      .includes(
        :student,
        :conceptual_exam_values,
        classroom: :unity
      )
      .filter(filtering_params(params[:search]))
      .by_unity(current_user_unity)
      .by_classroom(current_user_classroom)
      .by_discipline(current_user_discipline)
      .ordered

    authorize @conceptual_exams

    fetch_classrooms
    fetch_school_calendar_steps
    fetch_school_calendar_classroom_steps
  end

  def new
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
  end

  def update
    @conceptual_exam = ConceptualExam.find(params[:id])
    @conceptual_exam.assign_attributes(resource_params)

    authorize @conceptual_exam

    if @conceptual_exam.save
      respond_to_save
    else
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
  end

  def fetch_classrooms
    @classrooms = Classroom.where(id: current_user_classroom)
    .by_score_type(ScoreTypes::CONCEPT)
  end

  def fetch_school_calendar_steps
    @school_calendar_steps = current_school_calendar.steps
  end

  def fetch_school_calendar_classroom_steps
    @school_calendar_classroom_steps = SchoolCalendarClassroomStep.by_classroom(current_user_classroom.id)
  end

  def fetch_students
    @students = []

    if @conceptual_exam.classroom.present? && @conceptual_exam.recorded_at.present?
      @student_ids = StudentEnrollment
        .by_classroom(current_user_classroom)
        .by_discipline(current_user_discipline)
        .by_date(@conceptual_exam.recorded_at.to_date.to_s)
        .active
        .ordered
        .collect(&:student_id)
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

  def fetch_next_conceptual_exam
    next_student = fetch_next_student

    next_conceptual_exam = ConceptualExam.find_or_initialize_by(
      classroom_id: @conceptual_exam.classroom_id,
      school_calendar_step_id: @conceptual_exam.school_calendar_step_id,
      student_id: next_student.id
    )
    next_conceptual_exam.recorded_at = @conceptual_exam.recorded_at

    next_conceptual_exam
  end

  def fetch_next_student
    @students = fetch_students
    next_student_index = @students.find_index(@conceptual_exam.student) + 1

    if next_student_index == @students.length
      next_student_index = 0
    end

    @students[next_student_index]
  end
end
