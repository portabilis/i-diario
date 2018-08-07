class StudentEnrollmentsListsController < ApplicationController
  def by_date
    student_enrollments = StudentEnrollmentsList.new(
      classroom: params[:filter][:classroom],
      discipline: params[:filter][:discipline],
      score_type: params[:filter][:score_type],
      opinion_type: params[:filter][:opinion_type],
      with_recovery_note_in_step: ActiveRecord::Type::Boolean.new.type_cast_from_user(params[:filter][:with_recovery_note_in_step]),
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
      score_type: params[:filter][:score_type],
      opinion_type: params[:filter][:opinion_type],
      search_type: :by_date_range
    ).student_enrollments

    render json:  student_enrollments
  end
end
