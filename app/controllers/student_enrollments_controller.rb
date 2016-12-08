class StudentEnrollmentsController < ApplicationController
  def index
    student_enrollments = apply_scopes(StudentEnrollment).active.ordered

    render json: student_enrollments
  end
end
