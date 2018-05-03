class Api::V2::ClassroomStudentsController < Api::V2::BaseController
  respond_to :json

  def index
    student_list = fetch_students

    render json: student_list
  end

  def fetch_students
    return [] unless school_calendar

    frequency_date = params[:frequency_date] || Time.zone.today
    @student_enrollments = StudentEnrollment.
      includes(:student).
      by_classroom(params[:classroom_id]).
      by_discipline(params[:discipline_id]).
      by_date(frequency_date).
      exclude_exempted_disciplines(params[:discipline_id], step_number(frequency_date)).
      active.
      ordered
  end

  private

  def step_number(frequency_date)
    school_calendar.step(frequency_date).try(:to_number) || 0
  end

  def school_calendar
    classroom = Classroom.find(params[:classroom_id])

    @school_calendar ||=
      CurrentSchoolCalendarFetcher.new(classroom.unity, classroom).fetch
  end
end
