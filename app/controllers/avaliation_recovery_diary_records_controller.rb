class AvaliationRecoveryDiaryRecordsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_classroom
  before_action :require_current_teacher
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy]

  def index
    set_filters
    set_options_by_user
    set_avaliation_recovery_diary_records_by_user

    authorize @avaliation_recovery_diary_records

    @school_calendar_steps = steps_fetcher.steps
  end

  def new
    set_options_by_user

    @avaliation_recovery_diary_record = AvaliationRecoveryDiaryRecord.new.localized
    @avaliation_recovery_diary_record.build_recovery_diary_record
    @avaliation_recovery_diary_record.recovery_diary_record.unity = current_unity
    @avaliation_recovery_diary_record.recovery_diary_record.classroom = current_user_classroom
    @avaliation_recovery_diary_record.recovery_diary_record.discipline = current_user_discipline

    @unities = fetch_unities
    @school_calendar_steps = steps_fetcher.steps

    fetch_disciplines_by_classroom

    if current_test_setting.blank?
      flash[:error] = t('errors.avaliations.require_setting')

      redirect_to(avaliation_recovery_diary_records_path)
    end

    return if performed?

    @number_of_decimal_places = current_test_setting.number_of_decimal_places
  end

  def create
    @avaliation_recovery_diary_record = AvaliationRecoveryDiaryRecord.new.localized
    @avaliation_recovery_diary_record.assign_attributes(resource_params.to_h)
    @avaliation_recovery_diary_record.recovery_diary_record.teacher_id = current_teacher_id

    authorize @avaliation_recovery_diary_record

    if @avaliation_recovery_diary_record.save
      respond_with @avaliation_recovery_diary_record, location: avaliation_recovery_diary_records_path
    else
      set_options_by_user
      fetch_disciplines_by_classroom

      @number_of_decimal_places = current_test_setting.number_of_decimal_places
      reload_students_list if daily_note_students.present?

      render :new
    end
  end

  def edit
    set_options_by_user

    @avaliation_recovery_diary_record = AvaliationRecoveryDiaryRecord.find(params[:id]).localized

    fetch_disciplines_by_classroom

    authorize @avaliation_recovery_diary_record

    add_missing_students
    mark_not_existing_students_for_destruction

    @student_notes = fetch_student_notes
    @unities = fetch_unities
    @school_calendar_steps = steps_fetcher.steps
    @avaliations = fetch_avaliations
    reload_students_list

    @number_of_decimal_places = current_test_setting.number_of_decimal_places
  end

  def update
    @avaliation_recovery_diary_record = AvaliationRecoveryDiaryRecord.find(params[:id]).localized

    # Reorganiza resource_params quando temos alunos com enturmacoes ativas e inativas
    reload_resource_params = list_students_by_active(resource_params.to_h)

    @avaliation_recovery_diary_record.assign_attributes(reload_resource_params)
    @avaliation_recovery_diary_record.recovery_diary_record.teacher_id = current_teacher_id
    @avaliation_recovery_diary_record.recovery_diary_record.current_user = current_user

    authorize @avaliation_recovery_diary_record

    if @avaliation_recovery_diary_record.save
      respond_with @avaliation_recovery_diary_record, location: avaliation_recovery_diary_records_path
    else
      set_options_by_user
      fetch_disciplines_by_classroom

      @number_of_decimal_places = current_test_setting.number_of_decimal_places
      reload_students_list if daily_note_students.present?

      render :edit
    end
  end

  def history
    @avaliation_recovery_diary_record = AvaliationRecoveryDiaryRecord.find(params[:id])

    authorize @avaliation_recovery_diary_record

    respond_with @avaliation_recovery_diary_record
  end

  def destroy
    @avaliation_recovery_diary_record = AvaliationRecoveryDiaryRecord.find(params[:id])

    @avaliation_recovery_diary_record.recovery_diary_record.destroy

    respond_with @avaliation_recovery_diary_record, location: avaliation_recovery_diary_records_path
  end

  private

  def set_avaliation_recovery_diary_records_by_user
    @avaliation_recovery_diary_records = if current_user.current_role_is_admin_or_employee?
                                          avaliation_recovery_diary_records_for_admin
                                        else
                                          avaliation_recovery_diary_records_for_teacher
                                        end

    @avaliation_recovery_diary_records = @avaliation_recovery_diary_records.ordered
  end

  def avaliation_recovery_diary_records_for_teacher
    base_query
      .joins(recovery_diary_record: :classroom)
      .joins('INNER JOIN teacher_discipline_classrooms tdc ON tdc.classroom_id = classrooms.id AND tdc.discipline_id = recovery_diary_records.discipline_id')
      .where('tdc.teacher_id = ? AND tdc.discarded_at IS NULL AND tdc.year = ?', current_teacher.id, current_school_year)
      .by_unity_id(current_unity.id)
  end

  def avaliation_recovery_diary_records_for_admin
    base_query
      .by_classroom_id(@classrooms.pluck(:id))
      .by_discipline_id(@disciplines.pluck(:id))
  end

  def base_query
    apply_scopes(AvaliationRecoveryDiaryRecord)
      .select('DISTINCT ON (avaliation_recovery_diary_records.id, recovery_diary_records.recorded_at) avaliation_recovery_diary_records.*')
      .includes(:avaliation, recovery_diary_record: [:unity, :classroom, :discipline])
  end

  def resource_params
    params.require(:avaliation_recovery_diary_record).permit(
      :avaliation_id,
      recovery_diary_record_attributes: [
        :id,
        :unity_id,
        :classroom_id,
        :discipline_id,
        :recorded_at,
        students_attributes: [
          :id,
          :student_id,
          :score,
          :_destroy,
          :active
        ]
      ]
    )
  end

  def fetch_unities
    Unity.by_teacher(current_teacher.id).ordered
  end

  def fetch_classrooms
    Classroom.where(id: current_user_classroom).ordered
  end

  def fetch_disciplines
    Discipline.where(id: current_user_discipline).ordered
  end

  def mark_not_existing_students_for_destruction
    current_students.each do |current_student|
      current_student.mark_for_destruction unless student_belongs_to_recovery?(current_student.student.id)
    end
  end

  def student_belongs_to_recovery?(student_id)
    has_daily_note = daily_note_students.students.any? do |daily_note_student|
      daily_note_student.student.id == student_id
    end
    return true if has_daily_note

    (fetch_student_enrollments || []).any? { |enrollment| enrollment.student_id == student_id }
  end

  def missing_students
    missing_students = []
    daily_note_students.students.each do |daily_note_student|
      is_missing = @avaliation_recovery_diary_record.recovery_diary_record.students.none? do |recovery_diary_record_student|
        recovery_diary_record_student.student.id == daily_note_student.student.id
      end
      missing_students << daily_note_student.student if is_missing
    end
    missing_students
  end

  def daily_note_students
    DailyNote.find_by_avaliation_id(@avaliation_recovery_diary_record.avaliation_id)
  end

  def add_missing_students
    missing_students.each do |missing_student|
      @avaliation_recovery_diary_record.recovery_diary_record.students.build(student: missing_student)
    end
  end

  def fetch_student_notes
    student_notes = DailyNoteStudent.by_avaliation(@avaliation_recovery_diary_record.avaliation).pluck(:student_id, :note).flatten
    Hash[*student_notes]
  end

  def current_students
    @avaliation_recovery_diary_record.recovery_diary_record.students
  end

  def fetch_avaliations
    Avaliation
      .by_discipline_id(@avaliation_recovery_diary_record.recovery_diary_record.discipline_id)
      .by_classroom_id(@avaliation_recovery_diary_record.recovery_diary_record.classroom_id)
      .ordered
  end

  def fetch_student_enrollments
    return unless @avaliation_recovery_diary_record.avaliation
    return unless @avaliation_recovery_diary_record.recovery_diary_record.recorded_at

    @fetch_student_enrollments ||=
      StudentEnrollmentsList.new(classroom: @avaliation_recovery_diary_record.recovery_diary_record.classroom,
                                 grade: @avaliation_recovery_diary_record.avaliation.grade_ids,
                                 discipline: @avaliation_recovery_diary_record.recovery_diary_record.discipline,
                                 score_type: StudentEnrollmentScoreTypeFilters::NUMERIC,
                                 date: @avaliation_recovery_diary_record.recovery_diary_record.recorded_at,
                                 search_type: :by_date)
                            .student_enrollments
  end

  def reload_students_list
    return unless (student_enrollments = fetch_student_enrollments)

    recovery_diary_record = @avaliation_recovery_diary_record.recovery_diary_record

    return unless recovery_diary_record.recorded_at

    step_number = fetch_step_number(
      @avaliation_recovery_diary_record,
      recovery_diary_record.classroom_id,
      @avaliation_recovery_diary_record.avaliation.test_date
    )

    situations = StudentSituationsFetcher.call(
      enrollment_ids: student_enrollments.map(&:id),
      classroom: recovery_diary_record.classroom,
      discipline: recovery_diary_record.discipline,
      step_number: step_number,
      date: recovery_diary_record.recorded_at
    )

    existing_by_student_id = recovery_diary_record.students.index_by(&:student_id)

    @students = []
    student_enrollments.each do |student_enrollment|
      next unless (student = Student.find_by_id(student_enrollment.student_id))

        note_student = existing_by_student_id[student.id] ||
                       recovery_diary_record.students.build(student_id: student.id, student: student)
        note_student.dependence = situations[:dependencies][student_enrollment.id].present?
        note_student.active = situations[:active_on_date_ids].include?(student_enrollment.id)
        note_student.exempted_from_discipline = situations[:exemptions][student_enrollment.id].present?
        note_student.in_active_search = situations[:enrollments_in_active_search].include?(student_enrollment.id)

        @students << note_student
    end

    StudentsDisplaySequencer.call(@students)
  end

  def fetch_step_number(avaliation_recovery_diary_record, classroom_id, date)
    school_calendar = avaliation_recovery_diary_record.avaliation.school_calendar

    school_calendar_classroom = school_calendar.classrooms.find_by_classroom_id(classroom_id)

    return school_calendar_classroom.classroom_step(date) if school_calendar_classroom.present?

    school_calendar.step(date).to_number
  end

  def list_students_by_active(resource_params_hash)
    group_students = resource_params_hash['recovery_diary_record_attributes']['students_attributes'].group_by { |key, value| value['id'] }

    note_students_uniq = group_students.select { |_k, value| value.count == 1 }
                                       .values
                                       .flat_map { |student| student.map(&:second) }

    note_students_active = group_students.reject { |_k, value| value.count == 1 }
                                         .flat_map { |_k, value| value.map(&:second) }
                                         .reject { |student| student['active'] == 'false' }

    note_students_uniq.push(note_students_active)

    resource_params_hash['recovery_diary_record_attributes']['students_attributes'] = note_students_uniq.flatten

    resource_params_hash
  end

  def set_options_by_user
    return fetch_linked_by_teacher unless current_user.current_role_is_admin_or_employee?

    @classrooms ||= fetch_classrooms
    @disciplines ||= fetch_disciplines
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    @classrooms ||= @fetch_linked_by_teacher[:classrooms]
    @disciplines ||= @fetch_linked_by_teacher[:disciplines]
  end

  def fetch_disciplines_by_classroom
    return if current_user.current_role_is_admin_or_employee?

    classroom = @avaliation_recovery_diary_record.recovery_diary_record.classroom
    @disciplines = @disciplines.by_classroom(classroom).not_descriptor
  end

  def steps_fetcher
    classroom = if @avaliation_recovery_diary_record.present?
                  @avaliation_recovery_diary_record.recovery_diary_record.classroom
                else
                  current_user_classroom
                end

    @steps_fetcher ||= StepsFetcher.new(classroom)
  end

  def set_filters
    params[:filter] ||= {}
    params[:filter][:by_classroom_id] ||= current_user_classroom.id
    params[:filter][:by_discipline_id] ||= current_user_discipline.id

    @filter = OpenStruct.new(params[:filter])
  end
end
