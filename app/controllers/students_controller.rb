class StudentsController < ApplicationController

  def index
    return render json: nil if params[:classroom_id].blank?

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

    student_enrollments = StudentEnrollmentsList.new(
      classroom: params[:classroom_id],
      discipline: params[:discipline_id],
      date: date,
      search_type: :by_date,
      include_date_range: include_date_range,
      start_at: start_date,
      end_at: end_date,
      score_type: params[:score_type]
    ).student_enrollments

    students = student_enrollments.map(&:student)

    render json: students
  end

  def select2_remote
    students = StudentDecorator.data_for_select2_remote(params[:description])

    render json: students
  end

  def search_autocomplete
    students = Student.search(params[:q]).ordered
    structured_students = StudentDecorator.data_for_search_autocomplete(students)
    render json: structured_students
  end

  def recovery_lowest_note
    return render json: nil if params[:classroom_id].blank? || params[:date].blank?


    @students = StudentEnrollmentsList.new(
      classroom: params[:classroom_id],
      discipline: params[:discipline_id],
      search_type: :by_date,
      date: params[:date],
      score_type: params[:score_type]
    ).student_enrollments.map(&:student)


    render(
      json: @students,
      each_serializer: StudentLowestNoteSerializer,
      discipline: discipline,
      classroom: classroom,
      step: step,
      number_of_decimal_places: test_setting(classroom, step).number_of_decimal_places
    )
  end

  def in_recovery
    @students = StudentsInRecoveryFetcher.new(
      configuration,
      params[:classroom_id],
      params[:discipline_id],
      params[:step_id],
      params[:date].to_date.to_s
    ).fetch

    @students = @students.select do |student|
      student[:student_enrollment_classroom].left_at.blank? || student[:student_enrollment_classroom].left_at.to_date >= params[:date].to_date
    end.pluck(:student)

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
