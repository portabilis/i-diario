class StudentsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:search_api]

  def index
    @students = apply_scopes(Student)

    respond_with @students
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
    @students = []

    classroom = Classroom.find(params[:classroom_id])
    discipline = Discipline.find(params[:discipline_id])

    case classroom.exam_rule.recovery_type
    when RecoveryTypes::PARALLEL
      if classroom.exam_rule.parallel_recovery_average
        students = fetch_students(
          classroom.api_code,
          discipline.api_code
        )
        @students = students.select do |student|
          average = student.average(params[:discipline_id], params[:school_calendar_step_id])
          average < classroom.exam_rule.parallel_recovery_average
        end
      else
        @students = fetch_students(
          classroom.api_code,
          discipline.api_code
        )
      end
    when RecoveryTypes::SPECIFIC
      step = SchoolCalendarStep.find(params[:school_calendar_step_id])
      recovery_exam_rule = classroom.exam_rule.recovery_exam_rules.find { |r| r.steps.last.eql?(step.to_number) }
      if recovery_exam_rule
        school_calendar = step.school_calendar
        steps_ids = []
        school_calendar.steps.each do |s|
          if recovery_exam_rule.steps.include?(s.to_number)
            steps_ids << s.id
          end
        end

        students = fetch_students(
          classroom.api_code,
          discipline.api_code
        )

        @students = students.select do |student|
          sum_averages = 0
          steps_ids.each do |step_id|
            sum_averages = sum_averages + student.average(params[:discipline_id], step_id)
          end
          average = sum_averages / steps_ids.count
          average < recovery_exam_rule.average
        end
      end
    end

    render(
      json: @students,
      each_serializer: StudentInRecoverySerializer,
      discipline_id: params[:discipline_id],
      school_calendar_step_id: params[:school_calendar_step_id]
    )
  end

  private

  def configuration
    IeducarApiConfiguration.current
  end

  def fetch_students(classroom_api_code, discipline_api_code)
    api = IeducarApi::Students.new(configuration.to_api)
    result = api.fetch_for_daily(
      {
        classroom_api_code: classroom_api_code,
        discipline_api_code: discipline_api_code
      }
    )
    api_students = result['alunos']
    students_api_codes = api_students.map { |api_student| api_student['id'] }
    students = Student.where(api_code: students_api_codes).ordered

    students
  end
end
