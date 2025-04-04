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
    if current_user.current_role_is_admin_or_employee?
      @classrooms = [current_user_classroom]
      @disciplines = [current_user_discipline]
    else
      fetch_linked_by_teacher
    end

    if params[:filter].present? && params[:filter][:by_step_id].present?
      step_id = params[:filter].delete(:by_step_id)
      params[:filter][school_calendar_step] = step_id
    end

    fetch_avaliations_by_user

    authorize @avaliations
    respond_with @avaliations
  end

  def new
    return if test_settings_redirect
    return if score_types_redirect
    return if not_allow_numerical_exam

    fetch_linked_by_teacher unless current_user.current_role_is_admin_or_employee?
    grades
    @avaliation = resource
    @avaliation.school_calendar = current_school_calendar
    @avaliation.classroom = current_user_classroom
    @avaliation.discipline = current_user_discipline
    @avaliation.test_date = Time.zone.today

    fetch_disciplines_by_classroom

    authorize resource
  end

  def multiple_classrooms
    return if test_settings_redirect
    return if score_types_redirect
    return if not_allow_numerical_exam

    fetch_linked_by_teacher unless current_user.current_role_is_admin_or_employee?

    disciplines_for_multiple_classrooms
    set_avaliation_multiple_creator_by_user

    authorize Avaliation.new

    test_settings
  end

  def set_avaliation_multiple_creator_by_user
    @avaliation_multiple_creator_form = AvaliationMultipleCreatorForm.new.localized
    @avaliation_multiple_creator_form.school_calendar_id = current_school_calendar.id
    @avaliation_multiple_creator_form.discipline_id = current_user_discipline.id
    @avaliation_multiple_creator_form.unity_id = current_unity.id
    @avaliation_multiple_creator_form.load_avaliations!(current_teacher.id, current_school_calendar.year)
  end

  def create_multiple_classrooms
    authorize Avaliation.new
    params_avaliation_multiple = params[:avaliation_multiple_creator_form].to_unsafe_h

    @avaliation_multiple_creator_form = AvaliationMultipleCreatorForm.new(
      params_avaliation_multiple.merge(teacher_id: current_teacher_id)
    )

    if @avaliation_multiple_creator_form.save
      respond_with @avaliation_multiple_creator_form, location: avaliations_path
    else
      test_settings
      fetch_linked_by_teacher unless current_user.current_role_is_admin_or_employee?
      fetch_disciplines_by_classroom

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

      if current_user.current_role_is_admin_or_employee?
        grades
      else
        fetch_linked_by_teacher
      end
      fetch_disciplines_by_classroom
      test_settings

      render :new
    end
  end

  def edit
    fetch_linked_by_teacher unless current_user.current_role_is_admin_or_employee?

    @avaliation = resource
    @grades = @avaliation.grades

    test_settings
    fetch_disciplines_by_classroom

    authorize @avaliation
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
      fetch_linked_by_teacher unless current_user.current_role_is_admin_or_employee?
      fetch_disciplines_by_classroom
      test_settings

      render :edit
    end
  end

  def destroy
    authorize resource
    resource_name = 'Avaliação numérica'

    message = if resource.destroy
                { notice: t('flash.female.destroy.notice', resource_name: resource_name) }
              else
                { alert: t('flash.female.destroy.alert', resource_name: resource_name) }
              end

    redirect_to avaliations_path, message
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

  def set_type_score_for_discipline
    return if params[:classroom_id].blank? && params[:discipline_id].blank?

    classroom = Classroom.find(params[:classroom_id])
    discipline = Discipline.find(params[:discipline_id])

    score_types = []

    classroom.classrooms_grades.each do |classroom_grade|
      exam_rule = classroom_grade.exam_rule

      next if exam_rule.blank?

      differentiated_exam_rule = exam_rule.differentiated_exam_rule

      if differentiated_exam_rule.blank? || !classroom_grade.classroom.has_differentiated_students?
        score_types << discipline_score_type_by_exam_rule(exam_rule, classroom_grade.classroom, discipline)
      end

      score_types << discipline_score_type_by_exam_rule(differentiated_exam_rule, classroom_grade.classroom, discipline)
    end

    available_score_types = score_types.uniq

    render json: true if available_score_types.any? { |discipline_score_type| discipline_score_type == ScoreTypes::NUMERIC }
  end

  def discipline_score_type_by_exam_rule(exam_rule, classroom, discipline)
    return if exam_rule.blank?
    return unless (score_type = exam_rule.score_type)
    return if score_type == ScoreTypes::DONT_USE
    return score_type if [ScoreTypes::NUMERIC, ScoreTypes::CONCEPT].include?(score_type)

    TeacherDisciplineClassroom.find_by(
      classroom: classroom,
      teacher: current_teacher,
      discipline: discipline
    ).score_type
  end

  def set_avaliation_setting
    return if params[:classroom_id].blank?

    classroom = Classroom.find(params[:classroom_id])

    year_test_setting = TestSetting.where(year: classroom.year)

    test_settings ||= general_by_school_test_setting(year_test_setting) ||
      general_test_setting(year_test_setting) ||
      by_school_term_test_setting(year_test_setting)

    test_setting_tests = TestSettingTest.where(test_setting: test_settings)

    render json: test_setting_tests
  end

  def set_grades_by_classrooms
    return if params[:classroom_id].blank?

    classroom = Classroom.find(params[:classroom_id])

    grades = classroom.grades.ordered

    render json: grades
  end

  def check_if_allow_numeric_exam
    return if params[:classroom_id].blank?

    classroom = Classroom.find(params[:classroom_id])

    grades_by_numerical_exam = classroom.classrooms_grades
      .by_score_type([ScoreTypes::NUMERIC, ScoreTypes::NUMERIC_AND_CONCEPT])
      .map(&:grade)

    render json: true if grades_by_numerical_exam.present?
  end

  private

  def school_calendar_step
    return :by_school_calendar_classroom_step if school_calendar_by_classroom?

    :by_school_calendar_step
  end

  def school_calendar_by_classroom?
    classroom_ids = @classrooms.map(&:id)

    current_school_calendar.classrooms.where(classroom_id: classroom_ids).present?
  end

  def fetch_avaliations_by_user
    current_unity_id = current_unity.id if current_unity
    @avaliations = apply_scopes(Avaliation
      .includes(:classroom, :discipline, :test_setting_test)
      .by_unity_id(current_unity_id)
      .teacher_avaliations(
        current_teacher.id,
        @classrooms.map(&:id),
        @disciplines.map(&:id)
      )
        .order_by_classroom
        .ordered
                               )

    @steps = SchoolCalendarDecorator.current_steps_for_select2_by_classrooms(current_school_calendar, @classrooms)
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    @classrooms = @fetch_linked_by_teacher[:classrooms].by_score_type([ScoreTypes::NUMERIC, ScoreTypes::NUMERIC_AND_CONCEPT])
    @disciplines = @fetch_linked_by_teacher[:disciplines].by_score_type(ScoreTypes::NUMERIC).not_descriptor
    @classroom_grades = @fetch_linked_by_teacher[:classroom_grades]
    @grades = @classroom_grades.map(&:grade).uniq
  end

  def respond_to_save
    if params[:commit] == I18n.t('avaliations.form.save_and_edit_daily_notes')
      @daily_note = DailyNote.find_or_initialize_by(avaliation_id: resource.id)
      @daily_note.save if @daily_note.new_record?

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
    if current_user.current_role_is_admin_or_employee?
      return @disciplines ||= Discipline.by_unity_id(current_unity.id, current_school_year)
                                        .by_teacher_id(current_teacher.id, current_school_year)
                                        .ordered

    end

    fetch_linked_by_teacher
    @disciplines
  end

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

    false if current_user.current_role_is_admin_or_employee?
  end

  def test_settings
    return unless (year_test_setting = TestSetting.where(year: current_user_classroom.year))

    @test_settings ||= general_by_school_test_setting(year_test_setting) ||
      general_test_setting(year_test_setting) ||
      by_school_term_test_setting(year_test_setting)
  end

  def general_by_school_test_setting(year_test_setting, classroom = nil)
    classroom ||= classroom || current_user_classroom

    year_test_setting.where(exam_setting_type: ExamSettingTypes::GENERAL_BY_SCHOOL)
      .by_unities(classroom.unity)
      .where(
        "grades && ARRAY[?]::integer[] OR grades = '{}'",
        classroom.grade_ids
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

    if current_user.current_role_is_admin_or_employee?
      redirect_to avaliations_path, alert: t('avaliation.numeric_exam_absence')
    else
      flash.now[:alert] = t('avaliation.numeric_exam_absence')
      return false
    end
  end

  def not_allow_numerical_exam
    grades_by_numerical_exam = current_user.classroom
                                           .classrooms_grades
                                           .by_score_type([ScoreTypes::NUMERIC, ScoreTypes::NUMERIC_AND_CONCEPT])
                                           .map(&:grade)

    return if grades_by_numerical_exam.present?

    if current_user.current_role_is_admin_or_employee?
      redirect_to avaliations_path, alert: t('avaliation.grades_not_allow_numeric_exam')
    else
      flash.now[:alert] = t('avaliation.grades_not_allow_numeric_exam')
      return false
    end
  end

  def fetch_disciplines_by_classroom
    return if current_user.current_role_is_admin_or_employee?

    classrooms = [@avaliation.classroom] if @avaliation&.classroom

    classrooms ||= @avaliation_multiple_creator_form.avaliations.map(&:classroom)

    @disciplines = @disciplines.by_classroom_id(classrooms.map(&:id)).not_descriptor
    @grades = @classroom_grades.by_classroom_id(classrooms.map(&:id)).map(&:grade).uniq
  end

  def grades
    @grades = current_user_classroom
                .classrooms_grades
                .by_score_type([ScoreTypes::NUMERIC, ScoreTypes::NUMERIC_AND_CONCEPT])
                .map(&:grade)
  end
end
