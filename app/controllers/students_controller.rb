class StudentsController < ApplicationController
  skip_before_action :authenticate_user!, only: :search_api

  def index
    if params[:classroom_id].present?
      date = params[:date] || Date.current
      start_date = params[:start_date]

      if step_id = params[:step_id] || params[:school_calendar_classroom_step_id] || params[:school_calendar_step_id]
        step = steps_fetcher.steps.find(step_id)
        step_number = step.to_number
        start_date ||= step.start_at
        end_date ||= step.end_at
      end

      student_enrollments = StudentEnrollmentsList.new(
        classroom: params[:classroom_id],
        discipline: params[:discipline_id],
        date: date,
        search_type: :by_date,
        score_type: params[:score_type]
      ).student_enrollments

      student_enrollments.delete_if do |student_enrollment|
        joinde_at = StudentEnrollmentClassroom
                    .by_student_enrollment(student_enrollment.id)
                    .by_date(date)
                    .first
                    .joined_at

        joinde_at.to_date < start_date
      end

      student_ids = student_enrollments.collect(&:student_id)

      @students = Student.where(id: student_ids).order_by_sequence(@classroom, start_date, end_date)

      if params[:discipline_id].present? && step_number.present?
        @students.each do |student|
          student_enrollment = student_enrollments.find { |enrollment| enrollment.student_id == student.id }
          exempted_from_discipline = student_enrollment.exempted_disciplines.by_discipline(params[:discipline_id])
                                                                            .by_step_number(step_number)
                                                                            .any?
          student.exempted_from_discipline = exempted_from_discipline
        end
        @students.to_a.reject!(&:exempted_from_discipline) if @remove_exempted_from_discipline
      end

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
