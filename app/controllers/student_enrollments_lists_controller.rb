class StudentEnrollmentsListsController < ApplicationController
  def by_date
    student_enrollments = StudentEnrollmentsList.new(
      classroom: params[:filter][:classroom],
      discipline: params[:filter][:discipline],
      date: params[:filter][:date]
    ).student_enrollments

    render json:  student_enrollments
  end

  def by_date_range
    student_enrollments = StudentEnrollmentsList.new(
      classroom: params[:filter][:classroom],
      discipline: params[:filter][:discipline],
      start_at: params[:filter][:start_at],
      end_at: params[:filter][:end_at],
      search_type: :by_date_range
    ).student_enrollments

    render json:  student_enrollments
  end
end
