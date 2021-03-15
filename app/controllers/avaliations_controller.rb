class AvaliationsController < ApplicationController
  has_scope :page, default: 1, only: [:index]
  has_scope :per, default: 10, only: [:index]

  respond_to :html, :js, :json

  before_action :require_current_clasroom
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
    return if redirect_to_avaliations

    available_score_types = [teacher_differentiated_discipline_score_type, teacher_discipline_score_type]

    if available_score_types.none? { |discipline_score_type| discipline_score_type == ScoreTypes::NUMERIC }
      redirect_to avaliations_path, alert: t('avaliation.numeric_exam_absence')
    end

    @avaliation = resource
    @avaliation.school_calendar = current_school_calendar
    @avaliation.test_setting    = current_test_setting
    @avaliation.test_date       = Time.zone.today

    authorize resource

    steps_settings(current_test_setting.exam_setting_type)
  end

  def multiple_classrooms
    return if redirect_to_avaliations

    @avaliation_multiple_creator_form                    = AvaliationMultipleCreatorForm.new.localized
    @avaliation_multiple_creator_form.school_calendar_id = current_school_calendar.id
    @avaliation_multiple_creator_form.test_setting_id    = current_test_setting.id
    @avaliation_multiple_creator_form.discipline_id      = current_user_discipline.id
    @avaliation_multiple_creator_form.unity_id           = current_unity.id
    @avaliation_multiple_creator_form.load_avaliations!(current_teacher.id, current_school_calendar.year)

    authorize Avaliation.new

    steps_settings(current_test_setting.exam_setting_type)
  end

  def create_multiple_classrooms
    authorize Avaliation.new

    @avaliation_multiple_creator_form = AvaliationMultipleCreatorForm.new(
      params[:avaliation_multiple_creator_form].merge(teacher_id: current_teacher_id)
    )

    if @avaliation_multiple_creator_form.save
      respond_with @avaliation_multiple_creator_form, location: avaliations_path
    else
      steps_settings(current_test_setting.exam_setting_type)
      render :multiple_classrooms
    end
  end

  def create
    resource.assign_attributes(resource_params)
    resource.school_calendar = current_school_calendar
    resource.teacher_id = current_teacher_id

    authorize resource

    if resource.save
      respond_to_save
    else
      steps_settings(current_test_setting.exam_setting_type)

      render :new
    end
  end

  def edit
    @avaliation = resource

    authorize @avaliation

    steps_settings(current_test_setting.exam_setting_type)
  end

  def update
    @avaliation = resource
    @avaliation.localized.assign_attributes(resource_params)
    @avaliation.teacher_id = current_teacher_id
    @avaliation.current_user = current_user

    authorize @avaliation

    if resource.save
      respond_to_save
    else
      steps_settings(current_test_setting.exam_setting_type)

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
      respond_with resource, location: avaliations_path
    end
  end

  def disciplines_for_multiple_classrooms
    @disciplines_for_multiple_classrooms ||= Discipline.by_unity_id(current_unity.id)
                                                       .by_teacher_id(current_teacher.id)
                                                       .ordered
  end
  helper_method :disciplines_for_multiple_classrooms

  def classrooms_for_multiple_classrooms
    return [] unless @avaliation_multiple_creator_form.discipline_id.present?
    @classrooms_for_multiple_classrooms ||= Classroom.by_unity_id(current_unity.id)
                                                     .by_teacher_id(current_teacher.id)
                                                     .by_teacher_discipline(@avaliation_multiple_creator_form.discipline_id)
                                                     .ordered
  end
  helper_method :classrooms_for_multiple_classrooms

  def set_number_of_classes
    @number_of_classes = current_school_calendar.number_of_classes
  end

  def resource
    @avaliation ||= case params[:action]
    when 'new', 'create'
      Avaliation.new
    when 'edit', 'update', 'destroy', 'show'
      Avaliation.find(params[:id])
    end
  end

  def resource_params
    params.require(:avaliation).permit(:test_setting_id,
                                       :classroom_id,
                                       :discipline_id,
                                       :test_date,
                                       :classes,
                                       :description,
                                       :test_setting_test_id,
                                       :weight,
                                       :observations)
  end

  def interpolation_options
    return {} if resource.class != Avaliation

    reasons = []

    if resource.errors[:test_date].include?(t('errors.messages.not_allowed_to_post_in_date'))
      reasons << t('errors.messages.not_allowed_to_post_in_date')
    end

    if !resource.grades_allow_destroy
      reasons << t('avaliation.grades_avoid_destroy')
    end

    if !resource.recovery_allow_destroy
      reasons << t('avaliation.recovery_avoid_destroy')
    end

    { reason: reasons.join(" e ") }
  end

  def redirect_to_avaliations
    !test_setting? && redirect_to(avaliations_path)
  end

  def test_setting?
    return true if current_test_setting.present?

    flash[:error] = t('errors.avaliations.require_setting')

    false
  end

  def steps_settings(exam_setting_type)
    @test_settings = if exam_setting_type == ExamSettingTypes::BY_SCHOOL_TERM
                       TestSetting.where(
                         year: current_school_calendar.year,
                         exam_setting_type: exam_setting_type
                       ).ordered
                     else
                       []
                     end
  end
end
