class Api::V2::DailyFrequenciesController < Api::V2::BaseController
  respond_to :json

  def index
    frequency_type_resolver = FrequencyTypeResolver.new(classroom, teacher)

    if frequency_type_resolver.general?
      @daily_frequencies = DailyFrequency
        .by_classroom_id(params[:classroom_id])
        .general_frequency
    else
      @daily_frequencies = DailyFrequency
        .by_classroom_id(params[:classroom_id])
        .by_discipline_id(params[:discipline_id])
    end

    @daily_frequencies = @daily_frequencies
      .order_by_frequency_date_desc
      .order_by_unity
      .order_by_classroom
      .order_by_class_number
      .includes(:unity, :classroom, :discipline, :students)

    respond_with @daily_frequencies
  end

  def create
    if params[:class_numbers].present?
      process_multiple
    else
      process_one
    end
  end

  def current_user
    @current_user ||= User.find(user_id)
  end

  protected

  def teacher
    @teacher ||= Teacher.find_by_id(params[:teacher_id])
  end

  def process_one
    frequency_params = {
      unity_id: unity.id,
      classroom_id: classroom.id,
      discipline_id: params[:discipline_id],
      frequency_date: params[:frequency_date],
      class_number: params[:class_number],
      school_calendar: current_school_calendar
    }
    @daily_frequency = DailyFrequency.new(frequency_params)

    if @daily_frequency.valid?
      creator = DailyFrequenciesCreator.new(frequency_params)
      creator.find_or_create!
      render json: creator.daily_frequencies[0]
    else
      render json: @daily_frequency.errors.full_messages, status: 422
    end

  end

  def process_multiple
    frequency_params = {
      unity_id: unity.id,
      classroom_id: classroom.id,
      discipline_id: params[:discipline_id],
      frequency_date: params[:frequency_date],
      class_number: params[:class_numbers].first,
      school_calendar: current_school_calendar
    }

    @class_numbers = params[:class_numbers].split(",")

    @daily_frequency = DailyFrequency.new(frequency_params)

    unless @daily_frequency.valid?
      render json: @daily_frequency.errors.full_messages, status: 422
    else
      creator = DailyFrequenciesCreator.new(frequency_params, @class_numbers)
      creator.find_or_create!
      render json: creator.daily_frequencies
    end
  end

  def configuration
    @configuration ||= IeducarApiConfiguration.current
  end

  def current_school_calendar
    @current_school_calendar ||= CurrentSchoolCalendarFetcher.new(unity, classroom).fetch
  end

  def classroom
    @classroom ||= Classroom.find_by_id(params[:classroom_id])
  end

  def unity
    @unity ||= classroom.unity
  end

  def user_id
    @user_id ||= params[:user_id] || 1
  end
end
