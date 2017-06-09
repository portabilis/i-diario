# encoding: utf-8
class Api::V1::ClassroomStudentsController < Api::V1::BaseController
  respond_to :json

  def index
    student_list = fetch_students

    render json: student_list
  end

  def fetch_students
    frequency_date = params[:frequency_date] || Time.zone.today
    @student_enrollments = StudentEnrollment
      .includes(:student)
      .by_classroom(params[:classroom_id])
      .by_discipline(params[:discipline_id])
      .by_date(frequency_date)
      .active
      .ordered
  end
end
