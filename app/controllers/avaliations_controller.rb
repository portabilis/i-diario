class AvaliationsController < ApplicationController
  has_scope :page, default: 1, only: [:index]
  has_scope :per, default: 10, only: [:index]

  respond_to :html, :js, :json

  before_action :require_current_classroom
  before_action :require_current_teacher, except: [:search]
  before_action :set_number_of_classes, only: [
    :new, :create, :edit, :update, :multiple_classrooms, :create_multiple_classrooms
  ]
  before_action :require_allow_to_modify_prev_years, only: [
    :create, :update, :destroy, :create_multiple_classrooms
  ]

  def index
    current_unity_id = current_unity.id if current_unity

    if params[:filter].present? && params[:filter][:by_step_id].present?
      step_id = params[:filter].delete(:by_step_id)

      if current_school_calendar.classrooms.find_by_classroom_id(current_user_classroom.id)
        params[:filter][:by_school_calendar_classroom_step] = step_id
      else
        params[:filter][:by_school_calendar_step] = step_id
      end
    end

    @avaliations = apply_scopes(Avaliation).includes(:classroom, :discipline, :test_setting_test)
                                           .by_unity_id(current_unity_id)
                                           .by_classroom_id(current_user_classroom)
                                           .by_discipline_id(current_user_discipline)
                                           .ordered

    authorize @avaliations

    @classrooms = Classroom.where(id: current_user_classroom)
    @disciplines = Discipline.where(id: current_user_discipline)
    @steps = SchoolCalendarDecorator.current_steps_for_select2(current_school_calendar, current_user_classroom)

    respond_with @avaliations
  end

  def new
    return if test_settings_redirect
    return if score_types_redirect
    return if not_allow_numerical_exam

    @avaliation = resource
    @avaliation.school_calendar = current_school_calendar
    @avaliation.test_date = Time.zone.today

    authorize resource
  end

  def multiple_classrooms
    return if test_settings_redirect
    return if score_types_redirect
    return if not_allow_numerical_exam

    @avaliation_multiple_creator_form = AvaliationMultipleCreatorForm.new.localized
    @avaliation_multiple_creator_form.school_calendar_id = current_school_calendar.id
    @avaliation_multiple_creator_form.discipline_id = current_user_discipline.id
    @avaliation_multiple_creator_form.unity_id = current_unity.id
    @avaliation_multiple_creator_form.load_avaliations!(current_teacher.id, current_school_calendar.year)

    authorize Avaliation.new

    test_settings
  end

  def create_multiple_classrooms
    authorize Avaliation.new

    @avaliation_multiple_creator_form = AvaliationMultipleCreatorForm.new(
      params[:avaliation_multiple_creator_form].merge(teacher_id: current_teacher_id)
    )

    if @avaliation_multiple_creator_form.save
      respond_with @avaliation_multiple_creator_form, location: avaliations_path
    else
      test_settings

      render :multiple_classrooms
    end
  end

  def create
    resource.localized.assign_attributes(resource_params)
    resource.school_calendar = current_school_calendar
    resource.teacher_id = current_teacher_id

    authorize resource

    if resource.save
      respond_to_save
    else
      @avaliation = resource
      test_settings

      render :new
    end
  end

  def edit
    @avaliation = resource

    authorize @avaliation

    test_settings
  end

  def update
    @avaliation = resource
    @avaliation.localized.assign_attributes(resource_params)
    @avaliation.teacher_id = current_teacher_id
    @avaliation.current_user = current_user

    authorize @avaliation

    if resource.grade_ids.empty?
      flash[:error] = 'Série não pode ficar em branco'
      test_settings

      return render :edit
    else
      flash.clear
    end

    if resource.save
      respond_to_save
    else
      test_settings

      render :edit
    end
  end

  def destroy
    authorize resource

    resource.destroy

    respond_with resource, location: avaliations_path
  end

  def history
    @avaliation = Avaliation.find(params[:id])

    authorize @avaliation

    respond_with @avaliation
  end

  def search
    @avaliations = apply_scopes(Avaliation).ordered

    render json: @avaliations
  end

  def show
    render json: resource
  end

  private

  def respond_to_save
    if params[:commit] == I18n.t('avaliations.form.save_and_edit_daily_notes')
      creator = DailyNoteCreator.new(avaliation_id: resource.id)
      creator.find_or_create

      @daily_note = creator.daily_note

      if @daily_note.persisted?
        redirect_to edit_daily_note_path(@daily_note)
      else
        render 'daily_notes/new'
      end
    else
      redirect_to avaliations_path
    end
  end

  def disciplines_for_multiple_classrooms
    @disciplines_for_multiple_classrooms ||= Discipline.by_unity_id(current_unity.id)
                                                       .by_teacher_id(current_teacher.id)
                                                       .ordered
  end
  helper_method :disciplines_for_multiple_classrooms

  def classrooms_for_multiple_classrooms
    return [] if @avaliation_multiple_creator_form.discipline_id.blank?

    @classrooms_for_multiple_classrooms ||= Classroom.by_unity_id(current_unity.id)
                                                     .by_teacher_id(current_teacher.id)
                                                     .by_teacher_discipline(
                                                       @avaliation_multiple_creator_form.discipline_id
                                                     ).ordered
  end
  helper_method :classrooms_for_multiple_classrooms

  def set_number_of_classes
    @number_of_classes = current_school_calendar.number_of_classes
  end

  def resource
    @resource ||= case params[:action]
                  when 'new', 'create'
                    Avaliation.new
                  when 'edit', 'update', 'destroy', 'show'
                    Avaliation.find(params[:id])
                  end
  end

  def resource_params
    parameters = params.require(:avaliation).permit(
      :test_setting_id,
      :classroom_id,
      :discipline_id,
      :test_date,
      :classes,
      :description,
      :test_setting_test_id,
      :weight,
      :observations,
      :grade_ids
    )

    parameters[:grade_ids] = parameters[:grade_ids].split(',')

    parameters
  end

  def interpolation_options
    if action_name == 'destroy'
      reasons = []

      if resource.errors[:test_date].include?(t('errors.messages.not_allowed_to_post_in_date'))
        reasons << t('errors.messages.not_allowed_to_post_in_date')
      end

      reasons << t('avaliation.grades_avoid_destroy') unless resource.grades_allow_destroy
      reasons << t('avaliation.recovery_avoid_destroy') unless resource.recovery_allow_destroy

      { reason: reasons.join(' e ') }
    elsif ['create', 'create_multiple_classrooms'].include?(action_name)
      classrooms = if resource
                     [resource.classroom.description]
                   else
                     classroom_records = params[:avaliation_multiple_creator_form][:avaliations_attributes].values
                     included = classroom_records.select { |classroom_record| classroom_record['include'] == '1' }
                     included.map { |included_record| Classroom.find(included_record['classroom_id']).description }
                   end

      { resource_name: I18n.t('activerecord.models.avaliation.one'), classrooms: classrooms.join(', ') }
    end
  end

  def test_settings_redirect
    !test_setting? && redirect_to(avaliations_path)
  end

  def test_setting?
    return true if test_settings

    flash[:error] = t('errors.avaliations.require_setting')

    false
  end

  def test_settings
    return unless (year_test_setting = TestSetting.where(year: current_user_classroom.year))

    @test_settings ||= general_by_school_test_setting(year_test_setting) ||
                       general_test_setting(year_test_setting) ||
                       by_school_term_test_setting(year_test_setting)
  end

  def general_by_school_test_setting(year_test_setting)
    year_test_setting.where(exam_setting_type: ExamSettingTypes::GENERAL_BY_SCHOOL)
                     .by_unities(current_user_classroom.unity)
                     .where(
                       "grades && ARRAY[?]::integer[] OR grades = '{}'",
                       current_user_classroom.grade_ids
                     )
                     .presence
  end

  def general_test_setting(year_test_setting)
    year_test_setting.where(exam_setting_type: ExamSettingTypes::GENERAL).presence
  end

  def by_school_term_test_setting(year_test_setting)
    year_test_setting.where(exam_setting_type: ExamSettingTypes::BY_SCHOOL_TERM)
                     .order(:school_term_type_step_id)
                     .presence
  end

  def score_types_redirect
    available_score_types = (teacher_differentiated_discipline_score_types + teacher_discipline_score_types).uniq

    return if available_score_types.any? { |discipline_score_type| discipline_score_type == ScoreTypes::NUMERIC }

    redirect_to avaliations_path, alert: t('avaliation.numeric_exam_absence')
  end

  def not_allow_numerical_exam
    grades_by_numerical_exam = current_user_classroom.classrooms_grades.by_score_type(ScoreTypes::NUMERIC).map(&:grade)

    return if grades_by_numerical_exam.present?

    redirect_to avaliations_path, alert: t('avaliation.grades_not_allow_numeric_exam')
  end

  def grades
    @grades ||= current_user_classroom.classrooms_grades.by_score_type(ScoreTypes::NUMERIC).map(&:grade)
  end
  helper_method :grades
end
