class DailyNotesController < ApplicationController
  before_action :require_teacher
  before_action :require_current_school_calendar

  def new
    @daily_note = DailyNote.new

    authorize @daily_note

    fetch_unities
  end

  def create
    @daily_note = DailyNote.new(resource_params)

    if @daily_note.valid? && find_or_initialize_resource
      redirect_to edit_daily_note_path(@daily_note)
    else
      fetch_unities
      render :new
    end
  end

  def edit
    @daily_note = DailyNote.find(params[:id])

    authorize @daily_note

    fetch_students

    @students = []

    @api_students.each do |api_student|
      if student = Student.find_by(api_code: api_student['id'])
        @students << (@daily_note.students.where(student_id: student.id).first || @daily_note.students.build(student_id: student.id, student: student, dependence: api_student['dependencia']))
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
    @daily_note = DailyNote.find(params[:id])
    @daily_note.assign_attributes resource_params

    authorize @daily_note

    if @daily_note.save
      respond_with @daily_note, location: new_daily_note_path
    else
      render :edit
    end
  end

  def destroy
    @daily_note = DailyNote.find(params[:id])
    authorize(@daily_note)

    @daily_note.destroy

    respond_with @daily_note, location: new_daily_note_path
  end

  def history
    @daily_note = DailyNote.find(params[:id])

    authorize @daily_note

    respond_with @daily_note
  end

  protected

  def fetch_students
    begin
      api = IeducarApi::Students.new(configuration.to_api)
      result = api.fetch_for_daily({ classroom_api_code: @daily_note.classroom.api_code, discipline_api_code: @daily_note.discipline.api_code})

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
    fetcher = UnitiesClassroomsDisciplinesByTeacher.new(current_teacher.id, @daily_note.unity_id, @daily_note.classroom_id, @daily_note.discipline_id)
    fetcher.fetch!
    @unities = fetcher.unities
    @classrooms = fetcher.classrooms
    @disciplines = fetcher.disciplines
    @avaliations = fetcher.avaliations
  end

  def resource_params
    params.require(:daily_note).permit(
      :unity_id, :classroom_id, :discipline_id, :avaliation_id,
      students_attributes: [
        :id, :student_id, :note, :dependence
      ]
    )
  end

  def require_teacher
    unless current_teacher
      flash[:alert] = t('errors.daily_notes.require_teacher')
      redirect_to root_path
    end
  end

  private

  def find_or_initialize_resource
    @daily_note = DailyNote.find_or_initialize_by(resource_params)

    if @daily_note.new_record?
      fetch_students

      @api_students.each do |api_student|
        if student = Student.find_by(api_code: api_student['id'])
          @daily_note.students.build(student_id: student.id, daily_note: @daily_note)
        end
      end

      @daily_note.save
    else
      true
    end
  end
end
