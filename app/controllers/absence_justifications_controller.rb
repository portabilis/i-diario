class AbsenceJustificationsController < ApplicationController

  before_action :require_current_teacher
  before_action :require_current_school_calendar

  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    current_discipline = fetch_current_discipline

    @classrooms = Classroom.where(id: current_user_classroom)
    @absence_justifications = apply_scopes(AbsenceJustification.by_unity(current_user_unity)
                                                               .by_classroom(current_user_classroom)
                                                               .by_discipline_id(current_discipline)
                                                               .by_teacher(current_teacher)
                                                               .by_school_calendar(current_user_school_calendar)
                                                               .filter(filtering_params(params[:search]))
                                                               .includes(:student).ordered)

    authorize @absence_justifications
  end

  def new
    @absence_justification = AbsenceJustification.new.localized
    @absence_justification.absence_date = Time.zone.today
    @absence_justification.teacher = current_teacher
    @absence_justification.unity = current_user_unity
    @absence_justification.school_calendar = current_school_calendar
    fetch_collections

    authorize @absence_justification
  end

  def create
    @absence_justification = AbsenceJustification.new(resource_params)
    @absence_justification.teacher = current_teacher
    @absence_justification.unity = current_user_unity
    @absence_justification.school_calendar = current_school_calendar

    authorize @absence_justification

    if @absence_justification.save
      respond_with @absence_justification, location: absence_justifications_path
    else
      clear_invalid_dates
      fetch_collections
      render :new
    end
  end

  def edit
    @absence_justification = AbsenceJustification.find(params[:id]).localized
    @absence_justification.unity = current_user_unity
    fetch_collections

    authorize @absence_justification
  end

  def update
    @absence_justification = AbsenceJustification.find(params[:id])
    @absence_justification.assign_attributes resource_params
    @absence_justification.school_calendar = current_school_calendar if @absence_justification.persisted? && @absence_justification.school_calendar.blank?
    fetch_collections

    authorize @absence_justification

    if @absence_justification.save
      respond_with @absence_justification, location: absence_justifications_path
    else
      clear_invalid_dates
      render :edit
      fetch_collections
    end
  end

  def destroy
    @absence_justification = AbsenceJustification.find(params[:id])

    @absence_justification.destroy

    respond_with @absence_justification, location: absence_justifications_path
  end

  def history
    @absence_justification = AbsenceJustification.find(params[:id])

    authorize @absence_justification

    respond_with @absence_justification
  end

  protected

  def resource_params
    params.require(:absence_justification).permit(
      :student_id, :absence_date, :justification, :absence_date_end,
      :unity_id, :classroom_id, :discipline_id
    )
  end

  private

  def filtering_params(params)
    if params
      params.slice(:by_classroom, :by_student, :by_date)
    else
      {}
    end
  end

  protected

  def fetch_collections
    @unities = Unity.by_teacher(current_teacher_id).ordered
    @classrooms = Classroom.by_unity_and_teacher(current_user_unity, current_teacher_id)
  end

  def configuration
    @configuration ||= IeducarApiConfiguration.current
  end

  def fetch_current_discipline
    frequency_type_definer = FrequencyTypeDefiner.new(current_user_classroom, current_teacher)
    frequency_type_definer.define!

    if frequency_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE
      current_user_discipline
    else
      nil
    end
  end

  def clear_invalid_dates
    begin
      resource_params[:absence_date].to_date
    rescue ArgumentError
      @absence_justification.absence_date = ''
    end

    begin
      resource_params[:absence_date_end].to_date
    rescue ArgumentError
      @absence_justification.absence_date_end = ''
    end
  end
end
