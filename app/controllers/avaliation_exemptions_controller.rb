class AvaliationExemptionsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @avaliation_exemptions = apply_scopes(AvaliationExemption)
                             .includes(:avaliation)
                             .by_unity(current_user_unity)
                             .by_classroom(current_user_classroom)
                             .by_discipline(current_user_discipline)

    authorize @avaliation_exemptions
  end

  def new
    @avaliation_exemption = AvaliationExemption.new
    @school_calendar_year = current_school_calendar.year
    @school_calendar_steps = current_school_calendar.steps
    @school_calendar_classroom_steps = SchoolCalendarClassroomStep.by_classroom(current_user_classroom)
    authorize @avaliation_exemption
  end

  def create
    @avaliation_exemption = AvaliationExemption.new.localized
    @avaliation_exemption.assign_attributes(avaliation_exemption_params)

    authorize @avaliation_exemption

    if @avaliation_exemption.save
      respond_with @avaliation_exemption, location: avaliation_exemptions_path
    else
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

  private

  def avaliation_exemption_params
    params.require(:avaliation_exemption).permit(:student_id,
                                                 :avaliation_id,
                                                 :reason)
  end

  def fetch_collections
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
    if @avaliation_exemption.avaliation.classroom.present?
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
    @school_calendar_steps ||= SchoolCalendarStep.by_school_calendar_id(@avaliation_exemption.school_calendar_id)
  end

  def fetch_school_calendar_classroom_steps
    @school_calendar_classroom_steps = SchoolCalendarClassroomStep.by_classroom(current_user_classroom)
  end

  def configuration
    @configuration ||= IeducarApiConfiguration.current
  end

end
