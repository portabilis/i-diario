class StudentsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:search_api]

  def index
    if params[:classroom_id] && params[:date]
      classroom = Classroom.find(params[:classroom_id])

      @students = StudentsFetcher.new(
        classroom,
        nil,
        params[:date].to_date.to_s,
        params[:start_date]
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
        params[:school_calendar_step_id],
        params[:date].to_date.to_s
      )
      .fetch

    school_calendar_steps = RecoverySchoolCalendarStepsFetcher.new(
        params[:school_calendar_step_id],
        params[:classroom_id]
      )
      .fetch

    school_calendar_step = SchoolCalendarStep.find(params[:school_calendar_step_id])

    render(
      json: @students,
      each_serializer: StudentInRecoverySerializer,
      discipline_id: params[:discipline_id],
      classroom_id: params[:classroom_id],
      school_calendar_step_id: school_calendar_step.id,
      number_of_decimal_places: school_calendar_step.test_setting.number_of_decimal_places
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

  def configuration
    IeducarApiConfiguration.current
  end
end
