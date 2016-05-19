class AvaliationExemptionsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_school_calendar

  def index
    @avaliation_exemptions = apply_scopes(AvaliationExemption)
      .by_unity(current_user_unity)
    authorize @avaliation_exemptions
  end

  def new
    @avaliation_exemption = AvaliationExemption.new
    @current_user_unity_id = current_user_unity.id
    @school_calendar_year = current_school_calendar.year
    @unities = fetch_unities
    @school_calendar_steps = current_school_calendar.steps
    authorize @avaliation_exemption
  end

  def create
    @avaliation_exemption = AvaliationExemption.new.localized
    @avaliation_exemption.assign_attributes(avaliation_exemption_params)

    authorize @avaliation_exemption

    if @avaliation_exemption.save
      respond_with @avaliation_exemption, location: avaliation_exemptions_path
    else
      @current_user_unity_id = current_user_unity.id
      @school_calendar_year = current_school_calendar.year
      fetch_collections
      render :new
    end
  end

  def edit
    @avaliation_exemption = AvaliationExemption.find(params[:id]).localized
    authorize @avaliation_exemption
    fetch_collections
  end

  def update
    @avaliation_exemption = AvaliationExemption.find(params[:id]).localized

    authorize @avaliation_exemption

    if @avaliation_exemption.update_attributes(avaliation_exemption_params)
      respond_with @avaliation_exemption, location: avaliation_exemptions_path
    else
      @current_user_unity_id = current_user_unity.id
      @school_calendar_year = current_school_calendar.year
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

  def avaliation_exemption_params
    params.require(:avaliation_exemption).permit(:student_id,
                                                 :avaliation_id,
                                                 :reason)
  end

  def fetch_collections
    @unities = fetch_unities
    @courses = fetch_courses
    @grades = fetch_grades
    @classrooms = fetch_classrooms
    @avaliations = fetch_avaliations
    @disciplines = fetch_disciplines
    @students = fetch_students
    @school_calendar_steps = fetch_school_calendar_steps
  end

  def fetch_unities
    Unity.by_teacher(current_teacher)
  end

  def fetch_courses
    Course.by_unity(current_user_unity.id)
  end

  def fetch_grades
    Grade
      .by_unity(current_user_unity.id)
      .by_course(@avaliation_exemption.course_id)
  end

  def fetch_classrooms
    Classroom
      .by_unity(current_user_unity.id)
      .by_year(current_school_calendar.year)
      .by_grade(@avaliation_exemption.grade_id)
  end

  def fetch_disciplines
    Discipline
      .by_unity_id(current_user_unity.id)
      .by_grade(@avaliation_exemption.grade_id)
      .by_classroom(@avaliation_exemption.classroom_id)
  end

  def fetch_avaliations
    Avaliation
      .by_classroom_id(@avaliation_exemption.classroom_id)
      .by_discipline_id(@avaliation_exemption.discipline_id)
  end

  def fetch_students
    @students = []

    if @avaliation_exemption.classroom.present? && @avaliation_exemption.avaliation.test_date
      begin
        @students = StudentsFetcher.new(
          configuration,
          @avaliation_exemption.classroom.api_code,
          date: @avaliation_exemption.avaliation.test_date.to_s
        )
        .fetch
      rescue IeducarApi::Base::ApiError => e
        flash[:alert] = e.message
        render :new
      end
    end
  end

  def fetch_school_calendar_steps
    SchoolCalendarStep
      .by_school_calendar_id(@avaliation_exemption.school_calendar_id)
  end

  def configuration
    @configuration ||= IeducarApiConfiguration.current
  end

end
