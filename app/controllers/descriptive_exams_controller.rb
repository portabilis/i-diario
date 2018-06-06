class DescriptiveExamsController < ApplicationController
  before_action :require_teacher

  def new
    @descriptive_exam = DescriptiveExam.new

    authorize @descriptive_exam
    set_school_calendar_steps
    set_school_calendar_classroom_steps
  end

  def create
    @descriptive_exam = DescriptiveExam.new(resource_params)

    if(@descriptive_exam.valid?)
      if @descriptive_exam.school_calendar_classroom_step_id
        @descriptive_exam = DescriptiveExam.find_or_create_by(
          classroom: @descriptive_exam.classroom,
          school_calendar_classroom_step_id: @descriptive_exam.school_calendar_classroom_step_id,
          discipline_id: @descriptive_exam.discipline_id,
          opinion_type: @descriptive_exam.opinion_type
        )
      else
        @descriptive_exam = DescriptiveExam.find_or_create_by(
          classroom: @descriptive_exam.classroom,
          school_calendar_step_id: @descriptive_exam.school_calendar_step_id,
          discipline_id: @descriptive_exam.discipline_id,
          opinion_type: @descriptive_exam.opinion_type
        )
      end
      redirect_to edit_descriptive_exam_path(@descriptive_exam)
    else
      set_school_calendar_steps
      set_school_calendar_classroom_steps
      render :new
    end
  end

  def edit
    @descriptive_exam = DescriptiveExam.find(params[:id])

    authorize @descriptive_exam

    fetch_student_enrollments

    @students = []

    @student_enrollments.each do |student_enrollment|
      if student = Student.find_by_id(student_enrollment.student_id)
        exam_student = (@descriptive_exam.students.where(student_id: student.id).first || @descriptive_exam.students.build(student_id: student.id))
        exam_student.dependence = student_has_dependence?(student_enrollment, @descriptive_exam.discipline)
        exam_student.exempted_from_discipline = student_exempted_from_discipline?(student_enrollment, @descriptive_exam)
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

  def update
    @descriptive_exam = DescriptiveExam.find(params[:id])
    @descriptive_exam.assign_attributes resource_params

    authorize @descriptive_exam

    destroy_students_not_found

    if @descriptive_exam.save
      respond_with @descriptive_exam, location: new_descriptive_exam_path
    else
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

  protected

  def fetch_student_enrollments
    @student_enrollments = StudentEnrollmentsList.new(classroom: @descriptive_exam.classroom,
                                                     discipline: @descriptive_exam.discipline,
                                                     opinion_type: @descriptive_exam.opinion_type,
                                                     start_at: calendar_step.start_at,
                                                     end_at: calendar_step.end_at,
                                                     show_inactive_outside_step: false,
                                                     search_type: :by_date_range)
                                                .student_enrollments
  end

  def calendar_step
    @descriptive_exam.step || current_school_calendar_steps.started_after_and_before(Time.zone.today).first
  end

  def current_school_calendar_steps
    if current_user_classroom.calendar
      current_school_calendar.classrooms.find_by_classroom_id(current_user_classroom).classroom_steps
    else
      current_school_calendar.steps
    end
  end

  def configuration
    @configuration ||= IeducarApiConfiguration.current
  end

  def resource_params
    params.require(:descriptive_exam).permit(
      :classroom_id, :discipline_id, :school_calendar_step_id,
      :school_calendar_classroom_step_id, :opinion_type,
      students_attributes: [
        :id, :student_id, :value, :dependence
      ]
    )
  end

  def require_teacher
    unless current_teacher
      flash[:alert] = t('errors.descriptive_exams.require_teacher')
      redirect_to root_path
    end
  end

  def set_school_calendar_steps
    @school_calendar_steps =  current_school_calendar.steps.ordered || {}
  end

  def set_school_calendar_classroom_steps
    @school_calendar_classroom_steps = SchoolCalendarClassroomStep.by_classroom(current_user_classroom.id) || {}
  end

  def set_opinion_types(classroom)
    @opinion_types = []
    return unless classroom.is_a?(Classroom)

    if classroom.exam_rule.allow_descriptive_exam?
      @opinion_types << {
        id: classroom.exam_rule.opinion_type,
        text: 'Regular'
      }
    end

    if classroom.exam_rule.differentiated_exam_rule &&
       classroom.exam_rule.differentiated_exam_rule.allow_descriptive_exam? &&
       classroom.exam_rule.opinion_type != classroom.exam_rule.differentiated_exam_rule.opinion_type

      @opinion_types << {
        id: classroom.exam_rule.differentiated_exam_rule.opinion_type,
        text: 'Aluno com deficiência'
      }
    end
  end

  def destroy_students_not_found
    @descriptive_exam.students.each do |student|
      student_exists = resource_params[:students_attributes].any? do |student_params|
        student_params.last[:student_id].to_i == student.student.id
      end

      student.destroy unless student_exists
    end
  end

  def student_has_dependence?(student_enrollment, discipline)
    StudentEnrollmentDependence
      .by_student_enrollment(student_enrollment)
      .by_discipline(discipline)
      .any?
  end

  def student_exempted_from_discipline?(student_enrollment, descriptive_exam)
    if discipline_id = descriptive_exam.discipline.try(&:id)
      step_number ||= descriptive_exam.school_calendar_classroom_step.try(:to_number)
      step_number ||= descriptive_exam.school_calendar_step.to_number

      return student_enrollment.exempted_disciplines.by_discipline(discipline_id)
                                                    .by_step_number(step_number)
                                                    .any?
    end

    false
  end

  def any_student_exempted_from_discipline?
    (@students || []).any?(&:exempted_from_discipline)
  end
end
