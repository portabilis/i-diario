# encoding: utf-8
class DailyFrequenciesController < ApplicationController
  before_action :require_teacher
  before_action :set_number_of_classes, only: [:new, :create, :edit_multiple, :update_multiple]
  before_action :require_current_school_calendar

  def new
    @daily_frequency = DailyFrequency.new

    authorize @daily_frequency

    fetch_unities
  end

  def create
    @daily_frequency = DailyFrequency.new(resource_params)
    class_numbers = params[:class_numbers]

    if(@daily_frequency.valid?)
      @daily_frequencies = []

      if @daily_frequency.global_absence?
        params = resource_params
        params[:discipline_id] = nil
        @daily_frequencies << @daily_frequency =
            DailyFrequency.find_or_create_by(unity_id: resource_params[:unity_id],
                                              classroom_id: resource_params[:classroom_id],
                                              frequency_date: resource_params[:frequency_date],
                                              global_absence: true)
      else
        class_numbers.split(',').each do |class_number|
          params = resource_params
          params[:class_number] = class_number
          @daily_frequencies << @daily_frequency = DailyFrequency.find_or_create_by(params)
        end
      end
      redirect_to edit_multiple_daily_frequencies_path(daily_frequencies_ids: @daily_frequencies.map(&:id))
    else
      if !@daily_frequency.global_absence? && (class_numbers.nil? || class_numbers.empty?)
        flash[:alert] = 'É necessário informar as aulas quando Falta global não estiver preenchido!'
      end
      fetch_unities
      render :new
    end
  end

  def edit_multiple
    @daily_frequencies = DailyFrequency.where(id: params[:daily_frequencies_ids]).ordered
    @daily_frequency = @daily_frequencies.first

    authorize @daily_frequencies.first

    fetch_students

    @students = []

    @api_students.each do |api_student|
      if student = Student.find_by(api_code: api_student['id'])
        @students << student
        @daily_frequencies.each do |daily_frequency|
          (daily_frequency.students.where(student_id: student.id).first || daily_frequency.students.build(student_id: student.id))
        end
      end
    end
  end

  def update_multiple
    authorize DailyFrequency.new

    builder = DailyFrequencyStudentsBuilder.new(frequency_student_params[:daily_frequency_student])
    builder.build_all

    flash[:success] = t 'daily_frequencies.success'

    redirect_to new_daily_frequency_path
  end

  def history
    @daily_frequency = DailyFrequency.find(params[:id])

    authorize @daily_frequency

    respond_with @daily_frequency
  end

  protected

  def fetch_students
    begin
      api = IeducarApi::Students.new(configuration.to_api)
      Rails.logger.debug @daily_frequency.inspect
      result = api.fetch_for_daily({ classroom_api_code: @daily_frequency.classroom.api_code, discipline_api_code: @daily_frequency.discipline.try(:api_code) })

      @api_students = result["alunos"]
    rescue IeducarApi::Base::ApiError => e
      flash[:alert] = e.message
      @api_students = []
      redirect_to new_daily_frequency_path
    end
  end

  def configuration
    @configuration ||= IeducarApiConfiguration.current
  end

  def fetch_unities
    fetcher = UnitiesClassroomsDisciplinesByTeacher.new(current_teacher.id, @daily_frequency.unity_id, @daily_frequency.classroom_id, @daily_frequency.discipline_id)
    fetcher.fetch!
    @unities = fetcher.unities
    @classrooms = fetcher.classrooms
    @disciplines = fetcher.disciplines
    @avaliations = fetcher.avaliations
  end

  def resource_params
    params.require(:daily_frequency).permit(
      :unity_id, :classroom_id, :discipline_id, :global_absence, :frequency_date,
      students_attributes: [
        :id, :student_id, :note
      ]
    )
  end

  def frequency_student_params
    params.permit(
      daily_frequency_student: [:daily_frequency_id, :student_id, :present]
    )
  end

  def set_number_of_classes
    @number_of_classes = current_school_calendar.number_of_classes
  end

  def require_teacher
    unless current_teacher
      flash[:alert] = t('errors.daily_frequencies.require_teacher')
      redirect_to root_path
    end
  end
end
