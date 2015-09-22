class DescriptiveExamsController < ApplicationController
  before_action :require_teacher
  before_action :require_current_school_calendar


  def new
    @descriptive_exam = DescriptiveExam.new
    @unity_id = current_user_unity.id

    authorize @descriptive_exam

    fetch_unities
    set_school_calendar_steps
  end

  def create
    @descriptive_exam = DescriptiveExam.new(resource_params)
    @unity_id = params[:descriptive_exam][:unity]

    if(@descriptive_exam.valid?)
      @descriptive_exam = DescriptiveExam.find_or_create_by(
          classroom: @descriptive_exam.classroom,
          school_calendar_step_id: @descriptive_exam.school_calendar_step_id,
          discipline_id: @descriptive_exam.discipline_id
      )
      redirect_to edit_descriptive_exam_path(@descriptive_exam)
    else
      fetch_unities
      set_school_calendar_steps
      render :new
    end
  end

  def edit
    @descriptive_exam = DescriptiveExam.find(params[:id])

    authorize @descriptive_exam

    fetch_students

    @students = []

    @api_students.each do |api_student|
      if student = Student.find_by(api_code: api_student['id'])
        exam_student = (@descriptive_exam.students.where(student_id: student.id).first || @descriptive_exam.students.build(student_id: student.id))
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
    @descriptive_exam = DescriptiveExam.find(params[:id])
    @descriptive_exam.assign_attributes resource_params

    authorize @descriptive_exam

    if @descriptive_exam.save
      fetch_unities
      respond_with @descriptive_exam, location: new_descriptive_exam_path
    else
      render :edit
    end
  end

  protected

  def fetch_students
    begin
      api = IeducarApi::Students.new(configuration.to_api)
      result = api.fetch_for_daily({ classroom_api_code: @descriptive_exam.classroom.api_code, discipline_api_code: @descriptive_exam.discipline.try(:api_code)})

      @api_students = result["alunos"]
    rescue IeducarApi::Base::ApiError => e
      flash[:alert] = e.message
      fetch_unities
      render :new
    end
  end

  def configuration
    @configuration ||= IeducarApiConfiguration.current
  end

  def fetch_unities
    @unity_id ||= @descriptive_exam.unity.try(:id)
    fetcher = UnitiesClassroomsDisciplinesByTeacher.new(current_teacher.id, @unity_id, @descriptive_exam.classroom_id, @descriptive_exam.discipline_id)
    fetcher.fetch!
    @unities = current_user.admin? ? fetcher.unities : Unity.where(id: @unity_id)
    @classrooms = fetcher.classrooms
    @disciplines = fetcher.disciplines
  end

  def resource_params
    params.require(:descriptive_exam).permit(
      :classroom_id, :discipline_id, :school_calendar_step_id,
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
end