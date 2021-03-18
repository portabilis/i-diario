class StudentsController < ApplicationController
  skip_before_action :authenticate_user!, only: :search_api

  def index
    if params[:classroom_id].present?
      date = params[:date] || Date.current
      start_date = params[:start_date]
      end_date = params[:end_date]
      step_id = params[:step_id] || params[:school_calendar_classroom_step_id] || params[:school_calendar_step_id]

      if step_id.present?
        step = steps_fetcher.steps.find(step_id)
        start_date ||= step.start_at
        end_date ||= step.end_at
      end

      include_date_range = start_date.present? && end_date.present?

      student_enrollments_list = StudentEnrollmentsList.new(
        classroom: params[:classroom_id],
        discipline: params[:discipline_id],
        date: date,
        search_type: :by_date,
        include_date_range: include_date_range,
        start_at: start_date,
        end_at: end_date,
        score_type: params[:score_type]
      )

      student_enrollments = student_enrollments_list.student_enrollments
      student_ids = student_enrollments.collect(&:student_id)
      @students = Student.where(id: student_ids)
      @students = @students.order_by_sequence(@classroom, start_date, end_date) if include_date_range

      render json: @students
    else
      @students = apply_scopes(Student).ordered

      respond_with @students
    end
  end

  def select2_remote
    students = StudentDecorator.data_for_select2_remote(params[:description])

    render json: students
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
      number_of_decimal_places: test_setting(classroom, step).number_of_decimal_places
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
    @step ||= steps_fetcher.step_by_id(params[:step_id])
  end

  def test_setting(classroom, step)
    @test_setting ||= TestSettingFetcher.current(classroom, step)
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
