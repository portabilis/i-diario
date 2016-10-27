class DailyNotesController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_teacher
  before_action :require_current_school_calendar

  def index
    @daily_notes = apply_scopes(DailyNote)
                    .includes(:avaliation)
                    .by_classroom_id(current_user_classroom)
                    .by_discipline_id(current_user_discipline)
                    .order_by_avaliation_test_date_desc

    @classrooms = Classroom.where(id: current_user_classroom)
    @disciplines = Discipline.where(id: current_user_discipline)
    @avaliations = Avaliation
                    .by_classroom_id(current_user_classroom)
                    .by_discipline_id(current_user_discipline)

    authorize @daily_notes
  end

  def new
    @daily_note = DailyNote.new(
      unity: current_user_unity
    )

    authorize @daily_note

  end

  def create
    @daily_note = DailyNote.new(resource_params)

    if @daily_note.valid? && find_or_initialize_resource
      redirect_to edit_daily_note_path(@daily_note)
    else
      render :new
    end
  end

  def edit
    @daily_note = DailyNote.find(params[:id])

    authorize @daily_note

    fetch_student_enrollments

    @students = []

    @student_enrollments.each do |student_enrollment|
      if student = Student.find_by_id(student_enrollment.student_id)
        note_student = (@daily_note.students.where(student_id: student.id).first || @daily_note.students.build(student_id: student.id, student: student))
        note_student.dependence = student_has_dependence?(student_enrollment, @daily_note.discipline)
        note_student.exempted = student_exempted_from_avaliation?(student.id)
        @students << note_student
      end
    end

    @normal_students = []
    @dependence_students = []
    @any_exempted_student = any_exempted_student?

    @students.each do |student|
      @normal_students << student if !student.dependence?
      @dependence_students << student if student.dependence?
    end
  end

  def update
    @daily_note = DailyNote.find(params[:id]).localized
    @daily_note.assign_attributes resource_params

    authorize @daily_note

    destroy_students_not_found

    if @daily_note.save
      respond_with @daily_note, location: daily_notes_path
    else
      render :edit
    end
  end

  def destroy
    @daily_note = DailyNote.find(params[:id])
    authorize(@daily_note)

    @daily_note.destroy

    respond_with @daily_note, location: daily_notes_path
  end

  def history
    @daily_note = DailyNote.find(params[:id])

    authorize @daily_note

    respond_with @daily_note
  end

  def search
    @daily_notes = apply_scopes(DailyNote)

    render json: @daily_notes
  end

  protected

  def fetch_student_enrollments
    @student_enrollments = StudentEnrollment
      .by_classroom(@daily_note.classroom)
      .by_date(@daily_note.avaliation.test_date)
      .active
      .ordered
  end

  def configuration
    @configuration ||= IeducarApiConfiguration.current
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
      fetch_student_enrollments

      @student_enrollments.each do |student_enrollment|
        if student = Student.find_by_id(student_enrollment.student_id)
          @daily_note.students.build(student_id: student.id, daily_note: @daily_note)
        end
      end

      @daily_note.save
    else
      true
    end
  end

  def destroy_students_not_found
    @daily_note.students.each do |student|
      student_exists = resource_params[:students_attributes].any? do |student_params|
        student_params.last[:student_id].to_i == student.student.id
      end

      student.destroy unless student_exists || student.transfer_note.present?
    end
  end

  def remove_duplicated_students(students)
    unique_student_ids = []
    unique_students = []
    students.each do |student|
      unique_students << student unless unique_student_ids.include? student["id"]
      unique_student_ids << student["id"]
    end
    unique_students
  end

  def student_exempted_from_avaliation?(student_id)
    avaliation_id = @daily_note.avaliation_id
    is_exempted = AvaliationExemption
      .by_student(student_id)
      .by_avaliation(avaliation_id)
      .any?
    is_exempted
  end

  def any_exempted_student?
    avaliation_id = @daily_note.avaliation_id
    any_exempted_student = AvaliationExemption
      .by_avaliation(avaliation_id)
      .any?
    any_exempted_student
  end

  def student_has_dependence?(student_enrollment, discipline)
    StudentEnrollmentDependence
      .by_student_enrollment(student_enrollment)
      .by_discipline(discipline)
      .any?
  end
end
