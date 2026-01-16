class TransferNotesController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_classroom
  before_action :require_current_teacher
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy]

  def index
    set_options_by_user
    set_filters

    @transfer_notes = apply_scopes(TransferNote).includes({ classroom: :unity }, :discipline, :student)
                                                .by_classroom_id(@classrooms.map(&:id))
                                                .by_discipline_id(@disciplines.map(&:id))

    @steps = SchoolCalendarDecorator.current_steps_for_select2_by_classrooms(
      current_school_calendar,
      classrooms_for_steps_filter
    )

    authorize @transfer_notes
  end

  def new
    @transfer_note = TransferNote.new(
      unity_id: current_unity.id,
      classroom_id: current_user_classroom.id,
      discipline_id: current_user_discipline.id
    ).localized

    set_options_by_user
    fetch_disciplines_by_classroom

    authorize @transfer_note
  end

  def create
    @transfer_note = TransferNote.new.localized
    @transfer_note.assign_attributes(resource_params.to_unsafe_h.except(:daily_note_students_attributes))
    @transfer_note.step_number = @transfer_note.step.try(:step_number)
    @transfer_note.teacher = current_teacher

    authorize @transfer_note

    if @transfer_note.save
      update_daily_note_student(resource_params[:daily_note_students_attributes])

      respond_with @transfer_note, location: transfer_notes_path
    else
      set_options_by_user
      fetch_disciplines_by_classroom

      render :new
    end
  end

  def edit
    @transfer_note = TransferNote.find(params[:id]).localized
    @transfer_note.step_id = steps_fetcher.step(@transfer_note.step_number).try(:id)
    @students_ordered = @transfer_note.daily_note_students.ordered

    set_options_by_user
    fetch_disciplines_by_classroom

    authorize @transfer_note
  end

  def update
    @transfer_note = TransferNote.find(params[:id]).localized
    @transfer_note.current_user = current_user
    @transfer_note.assign_attributes(resource_params.to_unsafe_h)
    daily_note_students = resource_params[:daily_note_students_attributes]

    require_daily_note_student(daily_note_students)
    authorize @transfer_note

    if @transfer_note.save
      respond_with @transfer_note, location: transfer_notes_path
    else
      set_options_by_user
      fetch_disciplines_by_classroom

      render :new
    end
  end

  def current_notes
    return unless params[:step_id].present? && params[:student_id].present? && params[:recorded_at].present?

    step = StepsFetcher.new(Classroom.find(params[:classroom_id])).step_by_id(params[:step_id])
    end_date = step.end_at > params[:recorded_at].to_date ? params[:recorded_at].to_date : step.end_at
    avaliations = Avaliation.by_classroom_id(params[:classroom_id])
                            .by_discipline_id(params[:discipline_id])
                            .by_teacher(current_teacher.id)
                            .by_test_date_between(step.start_at, end_date)
                            .ordered_asc

    @daily_note_students = avaliations.map do |avaliation|
      daily_note = DailyNote.find_or_create_by!(
        avaliation_id: avaliation.id
      ).localized

      DailyNoteStudent.find_or_initialize_by(
        daily_note_id: daily_note.id,
        student_id: params[:student_id]
      ).localized
    end

    render(json: @daily_note_students, include: { daily_notes: [:avaliation] })
  end

  def history
    @transfer_note = TransferNote.find(params[:id]).localized

    authorize @transfer_note

    respond_with @transfer_note
  end

  def destroy
    @transfer_note = TransferNote.find(params[:id])
    @transfer_note.step_id = @transfer_note.step.try(:id)

    authorize @transfer_note

    @transfer_note.destroy

    respond_with(@transfer_note, location: transfer_notes_path)
  end

  def find_step_number_by_classroom
    classroom = Classroom.find(params[:classroom_id])
    step_numbers = StepsFetcher.new(classroom)&.steps
    steps = step_numbers.map { |step| { id: step.id, description: step.to_s } }

    render json: steps.to_json
  end

  def fetch_steps
    set_options_by_user
    classroom_id = params[:classroom_id]

    classrooms = if classroom_id.present? && classroom_id != 'empty'
                   classroom = @classrooms.find { |c| c.id == classroom_id.to_i }
                   classroom ? [classroom] : @classrooms
                 else
                   @classrooms
                 end

    steps = SchoolCalendarDecorator.current_steps_for_select2_by_classrooms(
      current_school_calendar,
      classrooms
    )

    render json: steps
  end

  private

  def resource_params
    params.require(:transfer_note).permit(
      :unity_id,
      :classroom_id,
      :discipline_id,
      :recorded_at,
      :student_id,
      :step_id,
      daily_note_students_attributes: [
        :id,
        :student_id,
        :daily_note_id,
        :note,
        :active
      ]
    )
  end

  def steps_fetcher
    @steps_fetcher ||= StepsFetcher.new(current_user_classroom)
  end

  def students
    @students = (@transfer_note.student_id.present? ? [@transfer_note.student] : [])
  end
  helper_method :students

  def set_options_by_user
    @admin_or_teacher = current_user.current_role_is_admin_or_employee?

    return fetch_linked_by_teacher unless @admin_or_teacher

    @classrooms ||= [current_user_classroom]
    @disciplines ||= [current_user_discipline]
  end

  def set_filters
    params[:filter] ||= {}
    params[:filter][:by_classroom_id] ||= current_user_classroom.id
    params[:filter][:by_discipline_id] ||= current_user_discipline.id

    @step_id = nil
    step_from_classroom_id = nil

    if params[:filter][:by_step_id].present?
      step_value = params[:filter].delete(:by_step_id)
      @step_id, step_from_classroom_id = step_value.split(':')
      params[:filter][:by_classroom_id] = step_from_classroom_id

      step_scope_key = school_calendar_step_for_classroom(step_from_classroom_id.to_i)
      params[:filter][step_scope_key] = @step_id
    end

    @filter = OpenStruct.new(params[:filter])
    @filter.by_step_id = @step_id.present? ? "#{@step_id}:#{step_from_classroom_id}" : nil
  end

  def school_calendar_step_for_classroom(classroom_id)
    if current_school_calendar.classrooms.exists?(classroom_id: classroom_id)
      :by_school_calendar_classroom_step
    else
      :by_school_calendar_step
    end
  end

  def classrooms_for_steps_filter
    filtered_classroom_id = params.dig(:filter, :by_classroom_id)
    classroom = @classrooms.find { |c| c.id == filtered_classroom_id.to_i }
    classroom ? [classroom] : @classrooms
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(
      current_teacher.id, current_unity, current_school_year
    )
    @classrooms ||= @fetch_linked_by_teacher[:classrooms].by_score_type([
                                                                          ScoreTypes::NUMERIC,
                                                                          ScoreTypes::NUMERIC_AND_CONCEPT
                                                                        ])
    @disciplines ||= @fetch_linked_by_teacher[:disciplines]
    @unities ||= @classrooms.map(&:unity).uniq
  end

  def update_daily_note_student(daily_note_students_attributes)
    ActiveRecord::Base.transaction do
      daily_note_students_attributes.values.each do |data|
        record = DailyNoteStudent.with_discarded.find_or_initialize_by(
          daily_note_id: data[:daily_note_id],
          student_id: data[:student_id]
        ).localized

        record.assign_attributes(
          note: data[:note],
          transfer_note_id: @transfer_note.id,
          discarded_at: '',
          active: true
        )
        record.save!
      end
    end
  end

  def require_daily_note_student(daily_note_students)
    data = daily_note_students.values.map(&:any?)

    flash[:alert] = t('errors.daily_note.at_least_one_daily_note_student') if data.include?(false)
  end

  def fetch_disciplines_by_classroom
    return if current_user.current_role_is_admin_or_employee?

    classroom = @transfer_note.classroom
    @disciplines = @disciplines.by_classroom(classroom).not_descriptor
  end
end
