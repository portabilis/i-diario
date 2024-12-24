class DescriptiveExamsController < ApplicationController
  before_action :require_current_classroom
  before_action :require_teacher
  before_action :require_allow_to_modify_prev_years, only: :update
  before_action :view_data, only: [:edit, :show]

  def new
    @descriptive_exam = DescriptiveExam.new(
      classroom_id: current_user_classroom.id
    )

    select_options_by_user
    validate_opinion_type

    unless current_user.current_role_is_admin_or_employee?
      classroom_id = @descriptive_exam.classroom_id
      @disciplines = @disciplines.by_classroom_id(classroom_id).not_descriptor
    end

    authorize @descriptive_exam
  end

  def create
    @descriptive_exam = DescriptiveExam.new(resource_params)
    @descriptive_exam.recorded_at = recorded_at_by_step
    @descriptive_exam.step_number = find_step_number
    @descriptive_exam.teacher_id = current_teacher_id

    if @descriptive_exam.valid?
      @descriptive_exam = find_or_create_descriptive_exam

      authorize @descriptive_exam if @new_descriptive_exam

      redirect_to edit_descriptive_exam_path(@descriptive_exam)
    else
      select_options_by_user(@descriptive_exam.classroom_id)
      validate_opinion_type

      render :new
    end
  end

  def update
    @descriptive_exam = DescriptiveExam.find(params[:id])
    @descriptive_exam.assign_attributes(resource_params)
    @descriptive_exam.step_id = find_step_id unless opinion_type_by_year?
    @descriptive_exam.teacher_id = current_teacher_id
    adjusted_period

    regular_expression = /contenteditable(([ ]*)?\=?([ ]*)?("(.*)"|'(.*)'))/
    @descriptive_exam.students.each do |exam_student|
      value_by_student = resource_params[:students_attributes].values.detect do |student|
        student[:student_id] == exam_student.student_id.to_s && student[:inactive_student] == 'false'
      end
      exam_student.value = value_by_student['value'] if value_by_student.present?
      exam_student.value.gsub!(regular_expression, '') if exam_student.value.present?
    end

    authorize @descriptive_exam

    if @descriptive_exam.save
      respond_with @descriptive_exam, location: new_descriptive_exam_path
    else
      fetch_students
      select_options_by_user(@descriptive_exam.classroom_id)
      validate_opinion_type

      render :edit
    end
  end

  def history
    @descriptive_exam = DescriptiveExam.find(params[:id])

    authorize @descriptive_exam

    respond_with @descriptive_exam
  end

  def find
    return render json: nil if params[:opinion_type].blank? ||
                               (params[:step_id].blank? && !opinion_type_by_year?(params[:opinion_type])) ||
                               params[:classroom_id].blank?

    classroom_id = params[:classroom_id].to_i
    discipline_id = params[:discipline_id].blank? ? nil : params[:discipline_id].to_i
    step_id = opinion_type_by_year?(params[:opinion_type]) ? nil : params[:step_id].to_i

    select_options_by_user(classroom_id)
    validate_opinion_type

    descriptive_exam_id = DescriptiveExam.by_classroom_id(classroom_id)
                                         .by_discipline_id(discipline_id)
    if step_id
      classroom = Classroom.find(classroom_id)
      descriptive_exam_id = descriptive_exam_id.by_step_id(classroom, step_id)
    end

    descriptive_exam_id = descriptive_exam_id.first&.id

    render json: descriptive_exam_id
  end

  def opinion_types
    select_options_by_user(params[:classroom_id])
    validate_opinion_type

    render json: @opinion_types.to_json
  end

  def find_step_number_by_classroom
    return if params[:classroom_id].blank?

    classroom = Classroom.find(params[:classroom_id])
    step_numbers = StepsFetcher.new(classroom)&.steps
    steps = step_numbers.map { |step| { id: step.id, description: step.to_s } }

    render json: steps.to_json
  end

  protected

  def resource_params
    params.require(:descriptive_exam).permit(
      :classroom_id,
      :discipline_id,
      :step_id,
      :recorded_at,
      :opinion_type,
      students_attributes: [
        :id, :student_id, :value, :dependence, :inactive_student
      ]
    )
  end

  def steps_fetcher
    classroom = @descriptive_exam&.classroom || current_user_classroom

    @steps_fetcher ||= StepsFetcher.new(classroom)
  end

  def find_step_id
    steps_fetcher.step(@descriptive_exam.step_number).try(:id)
  end

  def find_step_number
    steps_fetcher.step_by_id(@descriptive_exam.step_id).try(:step_number)
  end

  def find_or_create_descriptive_exam
    descriptive_exam = DescriptiveExam.by_classroom_id(@descriptive_exam.classroom_id)
                                      .by_discipline_id(@descriptive_exam.discipline_id)
                                      .by_step_id(@descriptive_exam.classroom, @descriptive_exam.step_id)
                                      .first
    @new_descriptive_exam = false

    if descriptive_exam.blank?
      descriptive_exam = DescriptiveExam.create!(
        classroom_id: @descriptive_exam.classroom_id,
        discipline_id: @descriptive_exam.discipline_id,
        recorded_at: @descriptive_exam.recorded_at,
        opinion_type: @descriptive_exam.opinion_type,
        step_id: @descriptive_exam.step_id,
        step_number: @descriptive_exam.step_number,
        teacher_id: @descriptive_exam.teacher_id
      )

      @new_descriptive_exam = true
    end

    descriptive_exam.teacher_id = @descriptive_exam.teacher_id if descriptive_exam.teacher_id.blank?
    descriptive_exam.update(opinion_type: @descriptive_exam.opinion_type)

    descriptive_exam
  end

  def opinion_type_by_year?(opinion_type = nil)
    [OpinionTypes::BY_YEAR,
     OpinionTypes::BY_YEAR_AND_DISCIPLINE].include?(opinion_type || @descriptive_exam.opinion_type)
  end

  def recorded_at_by_step
    @descriptive_exam.step_id = steps_fetcher.steps.first.id if opinion_type_by_year?

    date = if @descriptive_exam.step_id.present?
             steps_fetcher.step_by_id(@descriptive_exam.step_id).end_at
           else
             Date.current
           end

    Date.current > date ? date : Date.current
  end

  def fetch_dates_for_opinion_type_by_year
    return unless opinion_type_by_year?

    @start_at = steps_fetcher.steps.first.start_at
    @end_at = steps_fetcher.steps.last.end_at
  end

  def enrollment_classrooms_list
    fetch_dates_for_opinion_type_by_year

    @enrollment_classrooms_list ||= StudentEnrollmentClassroomsRetriever.call(
      classrooms: @descriptive_exam.classroom,
      disciplines: @descriptive_exam.discipline,
      opinion_type: @descriptive_exam.opinion_type,
      start_at: @start_at || @descriptive_exam.step.try(:start_at),
      end_at: @end_at || @descriptive_exam.step.try(:end_at),
      show_inactive_outside_step: false,
      search_type: :by_date_range,
      period: @period,
      remove_duplicate_student: true
    )
  end

  def fetch_students
    @students = []

    enrollment_classrooms_list.each do |enrollment_classroom|
      student = enrollment_classroom[:student]
      student_enrollment = enrollment_classroom[:student_enrollment]
      left_at = enrollment_classroom[:student_enrollment_classroom].left_at.to_date

      exam_student = (@descriptive_exam.students.where(student_id: student.id).first || @descriptive_exam.students.build(student_id: student.id))
      exam_student.dependence = student_has_dependence?(student_enrollment, @descriptive_exam.discipline)
      exam_student.exempted_from_discipline = student_exempted_from_discipline?(student_enrollment)
      regular_expression = /contenteditable(([ ]*)?\=?([ ]*)?("(.*)"|'(.*)'))/
      exam_student.value = exam_student.value.gsub(regular_expression, '') if exam_student.value.present?
      exam_student.inactive_student = left_at.present? && left_at < @descriptive_exam.step.try(:end_at)

      @students << exam_student
    end

    @any_student_exempted_from_discipline = any_student_exempted_from_discipline?
    @normal_students = []
    @dependence_students = []

    @students.each do |student|
      @normal_students << student unless student.dependence?
      @dependence_students << student if student.dependence?
    end
  end

  def require_teacher
    return if current_teacher

    flash[:alert] = t('errors.descriptive_exams.require_teacher')
    redirect_to root_path
  end

  def select_options_by_user(classroom_id = nil)
    if current_user.current_role_is_admin_or_employee?
      @classrooms = [current_user_classroom]
      @discipline = [current_user_discipline]
    else
      fetch_linked_by_teacher

      if classroom_id.present?
        classroom = Classroom.find(classroom_id)
        @exam_rules = classroom.classrooms_grades.map(&:exam_rule)
      end
    end

    if action_name.eql?('new') || action_name.eql?('find')
      @exam_rules = current_user_classroom.classrooms_grades.map(&:exam_rule)
    end
  end

  def validate_opinion_type
    if @exam_rules.blank?
      flash[:error] = t('descriptive_exams.new.exam_rule_not_found')
      redirect_to new_descriptive_exam_path && return
    end

    if [OpinionTypes::BY_YEAR, OpinionTypes::BY_STEP].exclude?(@exam_rules.first.opinion_type)
      @descriptive_exam.discipline_id = current_user_discipline.id
    end

    @opinion_types = []

    descriptive_exam_opinion_type = @exam_rules.find(&:allow_descriptive_exam?)&.opinion_type

    if descriptive_exam_opinion_type.present?
      @opinion_types << OpenStruct.new(id: descriptive_exam_opinion_type,
                                       text: 'Avaliação padrão (regular)',
                                       name: 'Avaliação padrão (regular)')
    end

    differentiated_opinion_type = @exam_rules.find do |exam_rule|
      exam_rule.differentiated_exam_rule&.allow_descriptive_exam? &&
        exam_rule.differentiated_exam_rule.opinion_type != descriptive_exam_opinion_type
    end&.differentiated_exam_rule&.opinion_type

    if differentiated_opinion_type.present?
      @opinion_types << OpenStruct.new(
        id: differentiated_opinion_type,
        text: 'Avaliação inclusiva (alunos com deficiência)',
        name: 'Avaliação inclusiva (alunos com deficiência)'
      )
    end

    if @opinion_types.blank?
      redirect_with_message(t('descriptive_exams.new.exam_rule_not_allow_descriptive_exam')) && return
    end

    @opinion_type = params.dig('descriptive_exam', 'opinion_type')
  end

  def student_has_dependence?(student_enrollment, discipline)
    StudentEnrollmentDependence.by_student_enrollment(student_enrollment)
      .by_discipline(discipline)
      .any?
  end

  def student_exempted_from_discipline?(student_enrollment)
    if discipline_id = @descriptive_exam.discipline.try(:id)
      step_number = @descriptive_exam.step.to_number

      return student_enrollment.exempted_disciplines.by_discipline(discipline_id)
        .by_step_number(step_number)
        .any?
    end

    false
  end

  def any_student_exempted_from_discipline?
    (@students || []).any?(&:exempted_from_discipline)
  end

  def current_teacher_period(classroom_id, discipline_id)
    TeacherPeriodFetcher.new(
      current_teacher.id,
      classroom_id,
      discipline_id
    ).teacher_period
  end

  def adjusted_period
    teacher_period = current_teacher_period(
      @descriptive_exam.classroom_id,
      @descriptive_exam.discipline_id,
    )
    @period = teacher_period != Periods::FULL.to_i ? teacher_period : nil
  end

  def redirect_with_message(message)
    flash[:alert] = message

    redirect_to root_path
  end

  private

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(
      current_teacher.id,
      current_unity,
      current_school_year
    )
    @classrooms ||= @fetch_linked_by_teacher[:classrooms]
    @disciplines ||= @fetch_linked_by_teacher[:disciplines]
    @classroom_grades ||= @fetch_linked_by_teacher[:classroom_grades]
  end

  def view_data
    @descriptive_exam = DescriptiveExam.find(params[:id]).localized

    authorize @descriptive_exam

    adjusted_period
    fetch_students
  end
end
