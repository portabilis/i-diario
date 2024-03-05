class DailyNotesController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_classroom
  before_action :require_teacher
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy]

  def index
    set_options_by_user

    if params[:filter].present? && params[:filter][:by_step_id].present?
      step_id = params[:filter].delete(:by_step_id)
      if current_school_calendar.classrooms.find_by_classroom_id(current_user_classroom.id)
        params[:filter][:by_school_calendar_classroom_step_id] = step_id
      else
        params[:filter][:by_school_calendar_step_id] = step_id
      end
    end

    fetch_daily_notes_and_avaliations

    authorize @daily_notes
  end

  def new
    @daily_note = DailyNote.new

    set_options_by_user

    authorize @daily_note
  end

  def create
    creator = DailyNoteCreator.new(resource_params)
    creator.find_or_create
    @daily_note = creator.daily_note

    if @daily_note.persisted?
      redirect_to edit_daily_note_path(@daily_note)
    else
      render :new
    end
  end

  def edit
    @daily_note = DailyNote.find(params[:id])

    authorize @daily_note

    student_enrollments = fetch_student_enrollments

    @students = []

    student_enrollments.each do |student_enrollment|
      if student = Student.find_by_id(student_enrollment.student_id)
        note_student = (@daily_note.students.where(student_id: student.id).first || @daily_note.students.build(student_id: student.id, student: student))
        note_student.active = student_active_on_date?(student_enrollment)
        note_student.dependence = student_has_dependence?(student_enrollment, @daily_note.discipline)
        note_student.exempted = student_exempted_from_avaliation?(student.id)
        note_student.exempted_from_discipline = student_exempted_from_discipline?(student_enrollment, @daily_note)
        note_student.in_active_search = ActiveSearch.new.in_active_search?(student_enrollment.id, @daily_note.avaliation.test_date)

        @students << note_student
      end
    end

    @normal_students = []
    @dependence_students = []
    @any_exempted_student = any_exempted_student?
    @any_inactive_student = any_inactive_student?
    @any_student_exempted_from_discipline = any_student_exempted_from_discipline?
    @any_in_active_search = any_in_active_search?

    @students.each do |student|
      @normal_students << student if !student.dependence
      @dependence_students << student if student.dependence
    end
  end

  def update
    @daily_note = DailyNote.find(params[:id]).localized
    @daily_note.assign_attributes(resource_params.to_h)

    authorize @daily_note

    destroy_students_not_found

    if @daily_note.save
      respond_with @daily_note, location: daily_notes_path
    else
      reload_students_list
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
    step_id = (params[:filter] || []).delete(:by_step_id)

    @daily_notes = apply_scopes(DailyNote)

    if step_id.present?
      classroom = Classroom.find(params[:filter][:by_classroom_id])
      @daily_notes = @daily_notes.by_step_id(classroom, step_id)
    end

    render json: @daily_notes
  end

  def exempt_students
    @students_ids = params[:exemption_students_ids].split(',')

    @students_ids.each do |student_id|
      begin
        avaliation_exemption = AvaliationExemption.find_or_initialize_by(
          student_id: student_id,
          avaliation_id: params[:exemption_avaliation_id]
        )
        avaliation_exemption.reason = params[:reason]
        avaliation_exemption.teacher_id = current_teacher_id
        avaliation_exemption.current_user = current_user

        delete_note(params[:id], student_id)

        avaliation_exemption.save!
      rescue Exception
        @students_ids.delete(student_id)
      end
    end

    @students_ids = @students_ids.to_json.html_safe
  end

  def undo_exemption
    @student_id = params[:student_id]
    avaliation_id = params[:avaliation_id]
    exemption = AvaliationExemption.find_by(student_id: @student_id, avaliation_id: avaliation_id)

    @student_id = nil if exemption.blank?
    begin
      exemption&.destroy!
    rescue ActiveRecord::RecordNotDestroyed
      @student_id = nil
    end
  end

  def fetch_classrooms
    set_options_by_user

    render json: @classrooms
  end

  protected

  def fetch_student_enrollments
    @students_enrollments ||= StudentEnrollmentsRetriever.call(
      classrooms: @daily_note.classroom,
      grades: @daily_note.avaliation.grade_ids,
      disciplines: @daily_note.discipline,
      date: @daily_note.avaliation.test_date,
      score_type: StudentEnrollmentScoreTypeFilters::NUMERIC,
      search_type: :by_date
    )
  end

  def reload_students_list
    @students = []

    @daily_note.students.each_with_index do |note_student, index|
      if student = Student.find_by_id(note_student.student_id)
        student_enrollment = StudentEnrollment
          .by_student(note_student.student_id)
          .by_classroom(@daily_note.classroom_id)
          .by_discipline(@daily_note.discipline_id)
          .by_score_type(StudentEnrollmentScoreTypeFilters::NUMERIC,@daily_note.classroom_id)
          .active
          .first

        note_student.dependence = student_has_dependence?(student_enrollment, @daily_note.discipline)
        note_student.exempted = student_exempted_from_avaliation?(student.id)
        note_student.active = student_active_on_date?(student_enrollment)

        @students << note_student
      end
    end

    @normal_students = []
    @dependence_students = []
    @any_exempted_student = any_exempted_student?
    @any_inactive_student = any_inactive_student?

    @students.each do |student|
      @normal_students << student if !student.dependence
      @dependence_students << student if student.dependence
    end
  end

  def student_active_on_date?(student_enrollment)
    StudentEnrollment
      .where(id: student_enrollment)
      .by_classroom(@daily_note.classroom)
      .by_date(@daily_note.avaliation.test_date)
      .any?
  end

  def student_displayable_as_inactive?(student_enrollment)
    StudentEnrollment
      .where(id: student_enrollment)
      .by_classroom(@daily_note.classroom)
      .by_discipline(@daily_note.discipline)
      .show_as_inactive
      .any?
  end

  def configuration
    @configuration ||= IeducarApiConfiguration.current
  end

  def resource_params
    params.require(:daily_note).permit(
      :avaliation_id,
      students_attributes: [
        :id, :student_id, :note, :active, :_destroy
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

  def set_options_by_user
    @admin_or_teacher = current_user.current_role_is_admin_or_employee?

    return fetch_linked_by_teacher unless @admin_or_teacher

    @classrooms ||= [current_user_classroom]
    @disciplines ||= [current_user_discipline]
    @steps ||= SchoolCalendarDecorator.current_steps_for_select2(current_school_calendar, current_user_classroom)
  end

  def fetch_daily_notes_and_avaliations
    @daily_notes = apply_scopes(DailyNote
      .includes(:avaliation)
      .by_unity_id(current_unity)
      .teacher_avaliations(
        current_teacher.id,
        @classrooms.map(&:id),
        @disciplines.map(&:id)
      )
      .order_by_classroom
      .order_by_avaliation_test_date_desc
    )

    @avaliations = Avaliation.by_classroom_id(@classrooms.map(&:id)).by_discipline_id(@disciplines.map(&:id))
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    @classrooms = @fetch_linked_by_teacher[:classrooms].by_score_type(ScoreTypes::NUMERIC)
    @disciplines = @fetch_linked_by_teacher[:disciplines].by_score_type(ScoreTypes::NUMERIC)
  end

  def destroy_students_not_found
    @daily_note.students.each do |student|
      student_exists = resource_params[:students_attributes].any? do |student_params|
        student_params.last[:student_id].to_i == student.student.id
      end

      student.destroy unless student_exists || student.transfer_note.present?
    end
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

  def any_inactive_student?
    any_inactive_student = false
    if @students
      @students.each do |student|
        any_inactive_student = true if !student.active
      end
    end
    any_inactive_student
  end

  def student_exempted_from_discipline?(student_enrollment, daily_note)
    discipline_id = daily_note.discipline.id
    test_date = daily_note.avaliation.test_date
    step = StepsFetcher.new(daily_note.classroom).step_by_date(test_date)
    step_number = step.to_number

    student_enrollment.exempted_disciplines.by_discipline(discipline_id)
                                           .by_step_number(step_number)
                                           .any?
  end

  def any_student_exempted_from_discipline?
    (@students || []).any?(&:exempted_from_discipline)
  end

  def delete_note(daily_note_id, student_id)
    return unless (student_note = DailyNoteStudent.find_by(daily_note_id: daily_note_id, student_id: student_id))

    student_note.update!(note: nil)
  end

  def any_in_active_search?
    (@students || []).any?(&:in_active_search)
  end
end
