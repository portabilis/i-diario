class StudentsController < ApplicationController
  skip_before_action :authenticate_user!, only: :search_api

  def index
    if params[:classroom_id].present?
      date = params[:date] || Date.today
      step_id = params[:step_id] || params[:school_calendar_classroom_step_id] || params[:school_calendar_step_id]
      step = steps_fetcher.steps.find(step_id)
      step_number = step.to_number
      start_date = params[:start_date] || step.start_at

      @students = StudentsFetcher.new(
        classroom,
        Discipline.find_by_id(params[:discipline_id]),
        date.to_date.to_s,
        start_date,
        params[:score_type] || StudentEnrollmentScoreTypeFilters::BOTH,
        step_number
      )
      .fetch

      render json: @students
    else
      @students = apply_scopes(Student).ordered

      respond_with @students
    end
  end

  def search_api
    begin
      api = IeducarApi::Students.new(configuration.to_api)
      result = api.fetch_by_cpf(params[:document], params[:student_code])

      render json: result["alunos"].to_json
    rescue IeducarApi::Base::ApiError => e
      render json: e.message, status: "404"
    end
  end

  def in_recovery
    @students = StudentsInRecoveryFetcher.new(
        configuration,
        params[:classroom_id],
        params[:discipline_id],
        params[:step_id],
        params[:date].to_date.to_s
      )
      .fetch

    render(
      json: @students,
      each_serializer: StudentInRecoverySerializer,
      discipline: discipline,
      classroom: classroom,
      step: step,
      number_of_decimal_places: step.test_setting.number_of_decimal_places
    )
  end

  def in_final_recovery
    @students = StudentsInFinalRecoveryFetcher.new(configuration)
      .fetch(
        params[:classroom_id],
        params[:discipline_id]
      )

    render(
      json: @students,
      each_serializer: StudentInFinalRecoverySerializer
    )
  end

  private

  def steps_fetcher
    @steps_fetcher ||= StepsFetcher.new(classroom)
  end

  def step
    @step ||= steps_fetcher.steps.find(params[:step_id])
  end

  def configuration
    IeducarApiConfiguration.current
  end

  def classroom
    @classroom ||= Classroom.find(params[:classroom_id])
  end

  def discipline
    @discipline ||= Discipline.find(params[:discipline_id])
  end
end
