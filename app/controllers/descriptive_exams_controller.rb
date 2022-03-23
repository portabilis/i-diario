class DescriptiveExamsController < ApplicationController
  before_action :require_current_classroom
  before_action :require_teacher
  before_action :adjusted_period, only: [:edit, :update]
  before_action :require_allow_to_modify_prev_years, only: :update
  before_action :view_data, only: [:edit, :show]

  def new
    @descriptive_exam = DescriptiveExam.new

    set_opinion_types

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
      set_opinion_types

      render :new
    end
  end

  def update
    @descriptive_exam = DescriptiveExam.find(params[:id])
    @descriptive_exam.assign_attributes(resource_params)
    @descriptive_exam.step_id = find_step_id unless opinion_type_by_year?
    @descriptive_exam.teacher_id = current_teacher_id

    authorize @descriptive_exam

    if @descriptive_exam.save
      respond_with @descriptive_exam, location: new_descriptive_exam_path
    else
      fetch_students

      render :edit
    end
  end

  def history
    @descriptive_exam = DescriptiveExam.find(params[:id])

    authorize @descriptive_exam

    respond_with @descriptive_exam
  end

  def opinion_types
    set_opinion_types(Classroom.find(params[:classroom_id]))

    render json: @opinion_types.to_json
  end

  def find
    return render json: nil if params[:step_id].blank? || params[:opinion_type].blank?

    discipline_id = params[:discipline_id].blank? ? nil : params[:discipline_id].to_i
    step_id = opinion_type_by_year?(params[:opinion_type].to_i) ? nil : params[:step_id].to_i

    set_opinion_types

    descriptive_exam_id = DescriptiveExam.by_classroom_id(current_user_classroom.id)
                                         .by_discipline_id(discipline_id)
                                         .by_step_id(current_user_classroom, step_id)
                                         .first
                                         &.id

    render json: descriptive_exam_id
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
        :id, :student_id, :value, :dependence
      ]
    )
  end

  def steps_fetcher
    @steps_fetcher ||= StepsFetcher.new(current_user_classroom)
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
    [OpinionTypes::BY_YEAR, OpinionTypes::BY_YEAR_AND_DISCIPLINE].include?(opinion_type || @descriptive_exam.opinion_type)
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

  def fetch_student_enrollments
    @student_enrollments = StudentEnrollmentsList.new(
      classroom: @descriptive_exam.classroom,
      discipline: @descriptive_exam.discipline,
      opinion_type: @descriptive_exam.opinion_type,
      start_at: @descriptive_exam.step.try(:start_at),
      end_at: @descriptive_exam.step.try(:end_at),
      show_inactive_outside_step: false,
      search_type: :by_date_range,
      period: @period
    ).student_enrollments
  end

  def fetch_students
    fetch_student_enrollments

    @students = []

    @student_enrollments.each do |student_enrollment|
      if student = Student.find_by_id(student_enrollment.student_id)
        exam_student = (@descriptive_exam.students.where(student_id: student.id).first || @descriptive_exam.students.build(student_id: student.id))
        exam_student.dependence = student_has_dependence?(student_enrollment, @descriptive_exam.discipline)
        exam_student.exempted_from_discipline = student_exempted_from_discipline?(student_enrollment)
        @students << exam_student
      end
    end

    @any_student_exempted_from_discipline = any_student_exempted_from_discipline?
    @normal_students = []
    @dependence_students = []

    @students.each do |student|
      @normal_students << student if !student.dependence?
      @dependence_students << student if student.dependence?
    end
  end

  def require_teacher
    unless current_teacher
      flash[:alert] = t('errors.descriptive_exams.require_teacher')
      redirect_to root_path
    end
  end

  def set_opinion_types
    exam_rules = current_user_classroom.classrooms_grades.map(&:exam_rule)

    if exam_rules.blank?
      redirect_with_message(t('descriptive_exams.new.exam_rule_not_found'))

      return
    end

    @opinion_types = []

    descriptive_exam_opinion_type = exam_rules.find(&:allow_descriptive_exam?)&.opinion_type

    if descriptive_exam_opinion_type.present?
      @opinion_types << OpenStruct.new(id: descriptive_exam_opinion_type,
                                       text: 'Avaliação padrão (regular)',
                                       name: 'Avaliação padrão (regular)')
    end

    differentiated_opinion_type = exam_rules.find { |exam_rule|
      exam_rule.differentiated_exam_rule&.allow_descriptive_exam? &&
        exam_rule.differentiated_exam_rule.opinion_type != descriptive_exam_opinion_type
    }&.differentiated_exam_rule&.opinion_type

    if differentiated_opinion_type.present?
      @opinion_types << OpenStruct.new(
        id: differentiated_opinion_type,
        text: 'Avaliação inclusiva (alunos com deficiência)',
        name: 'Avaliação inclusiva (alunos com deficiência)'
      )
    end

    if @opinion_types.blank?
      redirect_with_message(t('descriptive_exams.new.exam_rule_not_allow_descriptive_exam'))

      return
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

  def redirect_with_message(message)
    flash[:alert] = message

    redirect_to root_path
  end

  private

  def view_data
    @descriptive_exam = DescriptiveExam.find(params[:id]).localized

    authorize @descriptive_exam

    fetch_students
  end
end
