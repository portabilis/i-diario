class AvaliationExemptionsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy]

  def index
    set_options_by_user
    @avaliation_exemptions = apply_scopes(AvaliationExemption)
                             .includes(:avaliation)
                             .by_unity(current_unity)
                             .by_classroom(@classrooms.map(&:id))
                             .by_discipline(@disciplines.map(&:id))

    authorize @avaliation_exemptions
  end

  def new
    @avaliation_exemption = AvaliationExemption.new
    @school_calendar_year = current_school_calendar.year
    @school_calendar_steps = current_school_calendar.steps
    @school_calendar_classroom_steps = SchoolCalendarClassroomStep.by_classroom(
      current_user_classroom
    )
    @avaliation_exemption.build_avaliation
    @avaliation_exemption.avaliation.classroom = current_user_classroom
    @avaliation_exemption.avaliation.discipline = current_user_discipline

    set_options_by_user
    # Filtra turmas e disciplinas de acordo com a serie para evitar que o usuario selecione uma turma
    # de outra serie
    unless current_user.current_role_is_admin_or_employee?
      classroom_by_grade = current_user_classroom.classrooms_grades.first.grade_id
      @classrooms = @classrooms.by_grade(classroom_by_grade)
      @disciplines = @disciplines.by_classroom_id(current_user_classroom).not_descriptor
    end

    authorize @avaliation_exemption
  end

  def create
    @avaliation_exemption = AvaliationExemption.new.localized
    @avaliation_exemption.assign_attributes(avaliation_exemption_params)
    @avaliation_exemption.teacher_id = current_teacher_id

    authorize @avaliation_exemption

    if @avaliation_exemption.save
      respond_with @avaliation_exemption, location: avaliation_exemptions_path
    else
      set_options_by_user
      fetch_collections
      render :new
    end
  end

  def edit
    @avaliation_exemption = AvaliationExemption.find(params[:id]).localized

    authorize @avaliation_exemption

    fetch_collections
    set_options_by_user
  end

  def update
    @avaliation_exemption = AvaliationExemption.find(params[:id]).localized
    @avaliation_exemption.teacher_id = current_teacher_id
    @avaliation_exemption.current_user = current_user

    authorize @avaliation_exemption

    if @avaliation_exemption.update_attributes(avaliation_exemption_params)
      respond_with @avaliation_exemption, location: avaliation_exemptions_path
    else
      set_options_by_user
      fetch_collections
      render :edit
    end
  end

  def destroy
    @avaliation_exemption = AvaliationExemption.find(params[:id])

    authorize @avaliation_exemption

    @avaliation_exemption.destroy

    respond_with @avaliation_exemption, location: avaliation_exemptions_path, alert: @avaliation_exemption.errors.to_a
  end

  def history
    @avaliation_exemption = AvaliationExemption.find(params[:id]).localized

    authorize @avaliation_exemption

    respond_with @avaliation_exemption
  end

  private

  def avaliation_exemption_params
    params.require(:avaliation_exemption).permit(:student_id,
                                                 :avaliation_id,
                                                 :reason)
  end

  def fetch_collections
    @school_calendar_year = current_school_calendar.year
    fetch_avaliations
    fetch_students
    fetch_school_calendar_steps
    fetch_school_calendar_classroom_steps
  end

  def fetch_avaliations
    @avaliations ||= Avaliation.by_classroom_id(@avaliation_exemption.classroom_id)
      .by_discipline_id(@avaliation_exemption.discipline_id)
  end

  def fetch_students
    @students = []
    if @avaliation_exemption.avaliation.try(:classroom).present?
      @student_ids = StudentEnrollment
        .by_classroom(current_user_classroom)
        .by_discipline(current_user_discipline)
        .by_date(@avaliation_exemption.avaliation.test_date)
        .by_score_type(StudentEnrollmentScoreTypeFilters::NUMERIC, current_user_classroom)
        .active
        .ordered
        .collect(&:student_id)
      @students = Student.where(id: @student_ids)
    end
  end

  def fetch_school_calendar_steps
    @school_calendar_steps ||= current_school_calendar.steps
  end

  def fetch_school_calendar_classroom_steps
    @school_calendar_classroom_steps = SchoolCalendarClassroomStep.by_classroom(current_user_classroom)
  end

  def configuration
    @configuration ||= IeducarApiConfiguration.current
  end

  def set_options_by_user
    if current_user.current_role_is_admin_or_employee?
      @classrooms ||= [current_user_classroom]
      @disciplines ||= [current_user_discipline]
    else
      fetch_linked_by_teacher
    end
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    @classrooms = @fetch_linked_by_teacher[:classrooms]
    @disciplines ||= @fetch_linked_by_teacher[:disciplines].distinct
    @grades ||= @fetch_linked_by_teacher[:classroom_grades].map(&:grade).uniq
  end
end
