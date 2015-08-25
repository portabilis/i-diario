class ConceptualExamsController < ApplicationController
  before_action :require_teacher
  before_action :require_current_school_calendar


  def new
    @conceptual_exam = ConceptualExam.new

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
        @students << (@conceptual_exam.students.where(student_id: student.id).first || @conceptual_exam.students.build(student_id: student.id, dependence: api_student['dependencia']))
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
      result = api.fetch_for_daily({ classroom_api_code: @conceptual_exam.classroom.api_code, discipline_api_code: @conceptual_exam.discipline.api_code})

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
    fetcher = UnitiesClassroomsDisciplinesByTeacher.new(current_teacher.id, @conceptual_exam.unity.try(:id), @conceptual_exam.classroom_id, @conceptual_exam.discipline_id)
    fetcher.fetch!
    @unities = fetcher.unities
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
end