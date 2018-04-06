class StudentEnrollmentsController < ApplicationController
  def index
    student_enrollments = apply_scopes(StudentEnrollment).active.ordered
    if params[:score_type].present? && params[:filter][:by_classroom].present?
      student_enrollments = student_enrollments.by_score_type(params[:score_type], params[:filter][:by_classroom])
    end

    render json: student_enrollments
  end
end
