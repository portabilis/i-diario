class ConceptualExamsController < ApplicationController
  before_action :require_teacher
  before_action :require_current_school_calendar


  def new
    @conceptual_exam = ConceptualExam.new
    @unity_id = current_user_unity.id

    authorize @conceptual_exam

    fetch_unities
    set_school_calendar_steps
  end

  def create
    @conceptual_exam = ConceptualExam.new(resource_params)
    @unity_id = params[:conceptual_exam][:unity]

    if(@conceptual_exam.valid?)
      @conceptual_exam = ConceptualExam.find_or_create_by(resource_params)
      redirect_to edit_conceptual_exam_path(@conceptual_exam)
    else
      fetch_unities
      set_school_calendar_steps
      render :new
    end
  end

  def edit
    @conceptual_exam = ConceptualExam.find(params[:id])

    authorize @conceptual_exam

    fetch_students

    @students = []

    @api_students.each do |api_student|
      if student = Student.find_by(api_code: api_student['id'])
        exam_student = (@conceptual_exam.students.where(student_id: student.id).first || @conceptual_exam.students.build(student_id: student.id))
        exam_student.dependence = api_student['dependencia']
        @students << exam_student
      end
    end

    @normal_students = []
    @dependence_students = []

    @students.each do |student|
      @normal_students << student if !student.dependence?
      @dependence_students << student if student.dependence?
    end
  end

  def update
    @conceptual_exam = ConceptualExam.find(params[:id])
    @conceptual_exam.assign_attributes resource_params

    destroy_students_not_found

    authorize @conceptual_exam

    if @conceptual_exam.save
      fetch_unities
      respond_with @conceptual_exam, location: new_conceptual_exam_path
    else
      render :edit
    end
  end

  protected

  def fetch_students
    begin
      api = IeducarApi::Students.new(configuration.to_api)
      result = api.fetch_for_daily(
        {
          classroom_api_code: @conceptual_exam.classroom.api_code,
          discipline_api_code: @conceptual_exam.discipline.api_code,
          date: Time.zone.today
        }
      )

      @api_students = result["alunos"]
    rescue IeducarApi::Base::ApiError => e
      flash[:alert] = e.message
      fetch_unities
      @api_students = []
      render :new
    end
  end

  def configuration
    @configuration ||= IeducarApiConfiguration.current
  end

  def fetch_unities
    @unity_id ||= @conceptual_exam.unity.try(:id)
    fetcher = UnitiesClassroomsDisciplinesByTeacher.new(current_teacher.id, @unity_id, @conceptual_exam.classroom_id, @conceptual_exam.discipline_id)
    fetcher.fetch!
    @unities = current_user.admin? ? fetcher.unities : Unity.where(id: @unity_id)
    @classrooms = fetcher.classrooms
    @disciplines = fetcher.disciplines
  end

  def resource_params
    params.require(:conceptual_exam).permit(
      :classroom_id, :discipline_id, :school_calendar_step_id,
      students_attributes: [
        :id, :student_id, :value, :dependence
      ]
    )
  end

  def require_teacher
    unless current_teacher
      flash[:alert] = t('errors.conceptual_exams.require_teacher')
      redirect_to root_path
    end
  end

  def set_school_calendar_steps
    @school_calendar_steps =  current_school_calendar.steps.ordered || {}
  end

  private

  def destroy_students_not_found
    @conceptual_exam.students.each do |student|
      student_exists = resource_params[:students_attributes].any? do |student_params|
        student_params.last[:student_id].to_i == student.student.id
      end

      student.destroy unless student_exists
    end
  end
end
