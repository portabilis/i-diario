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
    @daily_note = DailyNote.find_or_initialize_by(resource_params)
    @daily_note.save if @daily_note.new_record?
    reload_students_list

    if @daily_note.persisted?
      redirect_to edit_daily_note_path(@daily_note)
    else
      render :new
    end
  end

  def edit
    @daily_note = DailyNote.find(params[:id])

    authorize @daily_note

    reload_students_list
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

  def set_enrollment_classrooms
    @student_enrollment_classrooms ||= StudentEnrollmentClassroomsRetriever.call(
      classrooms: @daily_note.classroom,
      grades: @daily_note.avaliation.grade_ids,
      disciplines: @daily_note.discipline,
      date: @daily_note.avaliation.test_date,
      score_type: StudentEnrollmentScoreTypeFilters::NUMERIC,
      search_type: :by_date
    )
  end

  def reload_students_list
    set_students_and_info
    set_student_enrollments_data

    set_enrollment_classrooms.each do |enrollment_classroom|
      student = enrollment_classroom[:student]
      student_enrollment_id = enrollment_classroom[:student_enrollment].id
      note_student = @daily_note.students.find_or_initialize_by(student_id: student.id)
      note_student.active = @active.include?(enrollment_classroom[:student_enrollment_classroom].id)
      note_student.dependence = @dependencies[student_enrollment_id] ? true : false
      note_student.exempted = @exempted_from_avaliation.map(&:student_id).include?(student.id) ? true : false
      note_student.exempted_from_discipline = @exempted_from_discipline[student_enrollment_id] ? true : false
      note_student.in_active_search = @active_search[@daily_note.test_date]&.include?(student_enrollment_id)

      @normal_students << note_student if !note_student.dependence
      @dependence_students << note_student if note_student.dependence
      @students << note_student
    end

    @any_exempted_student = @students.select(&:exempted).any?
    @any_inactive_student = @students.reject(&:active).any?
    @any_student_exempted_from_discipline = @students.select(&:exempted_from_discipline).any?
    @any_in_active_search = @students.select(&:in_active_search).any?
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
    @classrooms = @fetch_linked_by_teacher[:classrooms].by_score_type([ScoreTypes::NUMERIC, ScoreTypes::NUMERIC_AND_CONCEPT])
    @disciplines = @fetch_linked_by_teacher[:disciplines].by_score_type(ScoreTypes::NUMERIC)
  end

  def destroy_students_not_found
    student_params = resource_params[:students_attributes]&.to_h

    @daily_note.students.each do |student|
      student_exists = student_params.any? do |_, params|
        params[:student_id].to_i == student.student.id
      end

      student.destroy unless student_exists || student.transfer_note.present?
    end
  end

  def delete_note(daily_note_id, student_id)
    return unless (student_note = DailyNoteStudent.find_by(daily_note_id: daily_note_id, student_id: student_id))

    student_note.update!(note: nil)
  end

  def set_students_and_info
    @students = []
    @normal_students = []
    @dependence_students = []

    @discipline = @daily_note.discipline
    @avaliation_id = @daily_note.avaliation_id
    @test_date = @daily_note.avaliation.test_date
    @step = StepsFetcher.new(@daily_note.classroom).step_by_date(@test_date)
  end

  def set_student_enrollments_data
    @student_enrollment_ids = set_enrollment_classrooms.map { |student_enrollment|
      student_enrollment[:student_enrollment].id
    }
    @student_ids = set_enrollment_classrooms.map { |student_enrollment|
      student_enrollment[:student].id
    }
    @dependencies = StudentsInDependency.call(student_enrollments: @student_enrollment_ids, disciplines: @discipline)
    @exempted_from_discipline = StudentsExemptFromDiscipline.call(
      student_enrollments: @student_enrollment_ids, discipline: @discipline, step: @step
    )
    @exempted_from_avaliation = students_exempted_from_avaliations(@avaliation_id, @student_ids)
    @active = ActiveStudentsOnDate.call(student_enrollments: @student_enrollment_ids, date: @test_date)
    @active_search = in_active_searches
  end

  def in_active_searches
    @in_active_searches ||= ActiveSearch.new.enrollments_in_active_search?(@student_enrollment_ids, @test_date)
  end

  def students_exempted_from_avaliations(avaliation_id, student_ids)
    students_exempt_from_avaliation = {}

    exemptions = AvaliationExemption.by_student(student_ids).by_avaliation(avaliation_id)

    return {} unless exemptions

    exemptions.each do |exempt|
      students_exempt_from_avaliation[exempt.student_id] ||= []
      students_exempt_from_avaliation[exempt.student_id] << exempt.avaliation_id
    end
  end
end
