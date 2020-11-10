class ConceptualExamsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_clasroom
  before_action :require_current_teacher
  before_action :adjusted_period
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy]

  def index
    step_id = (params[:filter] || []).delete(:by_step)
    status = (params[:filter] || []).delete(:by_status)

    @conceptual_exams = apply_scopes(ConceptualExam).includes(:student, :classroom)
                                                    .by_unity(current_unity)
                                                    .by_classroom(current_user_classroom)
                                                    .by_teacher(current_teacher_id)
                                                    .ordered_by_date_and_student

    if step_id.present?
      @conceptual_exams = @conceptual_exams.by_step_id(current_user_classroom, step_id)
      params[:filter][:by_step] = step_id
    end

    if status.present?
      @conceptual_exams = @conceptual_exams.by_status(current_user_classroom, current_teacher_id, status)
      params[:filter][:by_status] = status
    end

    authorize @conceptual_exams
  end

  def new
    discipline_score_types = [teacher_differentiated_discipline_score_type, teacher_discipline_score_type]

    not_concept_score = discipline_score_types.none? { |discipline_score_type|
      discipline_score_type == ScoreTypes::CONCEPT
    }

    if not_concept_score
      redirect_to(
        conceptual_exams_path,
        alert: I18n.t('conceptual_exams.new.current_discipline_does_not_have_conceptual_exam')
      )
    end

    return if performed?

    @conceptual_exam = ConceptualExam.new(
      unity_id: current_unity.id,
      classroom_id: current_user_classroom.id,
      recorded_at: Date.current
    ).localized

    if params[:conceptual_exam].present?
      @conceptual_exam.assign_attributes(resource_params)
    end

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
      @conceptual_exam = find_or_initialize_conceptual_exam
      authorize @conceptual_exam
      @conceptual_exam.assign_attributes(resource_params)
      @conceptual_exam.merge_conceptual_exam_values
      @conceptual_exam.step_number = @conceptual_exam.step.try(:step_number)
      @conceptual_exam.teacher_id = current_teacher_id
      @conceptual_exam.current_user = current_user

      respond_to_save if @conceptual_exam.save
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    return if performed?

    fetch_collections
    mark_not_existing_disciplines_as_invisible

    render :new
  end

  def edit
    @conceptual_exam = ConceptualExam.find(params[:id]).localized
    @conceptual_exam.unity_id = @conceptual_exam.classroom.unity_id
    @conceptual_exam.step_id = find_step_id

    authorize @conceptual_exam

    fetch_collections

    add_missing_disciplines
    mark_not_assigned_disciplines_for_destruction
    mark_not_existing_disciplines_as_invisible
    mark_exempted_disciplines
  end

  def update
    @conceptual_exam = ConceptualExam.find(params[:id])
    @conceptual_exam.assign_attributes(resource_params)
    @conceptual_exam.teacher_id = current_teacher_id
    @conceptual_exam.current_user = current_user

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
    @conceptual_exam.unity_id = @conceptual_exam.classroom.unity_id
    @conceptual_exam.step_id = find_step_id
    @conceptual_exam.validation_type = :destroy

    authorize @conceptual_exam

    if @conceptual_exam.valid?
      current_teacher_disciplines = Discipline.by_teacher_and_classroom(current_teacher.id, current_user_classroom.id)
      values_to_destroy = ConceptualExamValue.by_conceptual_exam_id(@conceptual_exam.id)
                                             .by_discipline_id(current_teacher_disciplines)

      values_to_destroy.each(&:destroy)
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
    step = steps_fetcher.step_by_id(params[:step_id])
    student_enrollments = student_enrollments(step.start_at, step.end_at)

    exempted_disciplines = student_enrollments.find do |item|
      item[:student_id] == params[:student_id].to_i
    end.exempted_disciplines

    render json:exempted_disciplines.by_step_number(step.to_number)
  end

  def find_conceptual_exam_by_student
    render json: find_conceptual_exam.try(:id)
  end

  private

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
    steps_fetcher.step(@conceptual_exam.step_number).try(:id)
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

    (@disciplines || []).each do |discipline|
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

    @student_enrollments ||= student_enrollments(@conceptual_exam.step.start_at, @conceptual_exam.step.end_at)

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
    if @conceptual_exam.step_id.present?
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

    @disciplines = @disciplines.where.not(id: exempted_discipline_ids)
  end

  def steps_fetcher
    @steps_fetcher ||= StepsFetcher.new(current_user_classroom)
  end

  def student_enrollments(start_at, end_at)
    StudentEnrollmentsList.new(
      classroom: current_user_classroom,
      discipline: current_user_discipline,
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
      @student_enrollments ||= student_enrollments(@conceptual_exam.step.start_at, @conceptual_exam.step.end_at)

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

  def current_teacher_period
    TeacherPeriodFetcher.new(
      current_teacher.id,
      current_user.current_classroom_id,
      current_user.current_discipline_id
    ).teacher_period
  end

  def adjusted_period
    teacher_period = current_teacher_period
    @period = teacher_period != Periods::FULL.to_i ? teacher_period : nil
  end
end
