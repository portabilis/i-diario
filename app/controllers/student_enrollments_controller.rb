class StudentEnrollmentsController < ApplicationController
  def index
    student_enrollments = apply_scopes(StudentEnrollment).active.ordered
    if params[:score_type].present? && params[:filter][:by_classroom].present?
      student_enrollments = student_enrollments.by_score_type(params[:score_type], params[:filter][:by_classroom])
    end

    if params[:exclude_exempted_disciplines].present?
      step ||= SchoolCalendarClassroomStep.find_by_id(params[:school_calendar_classroom_step_id])
      step ||= SchoolCalendarStep.find(params[:school_calendar_step_id])
      student_enrollments = student_enrollments.exclude_exempted_disciplines(params[:filter][:by_discipline], step.to_number)
    end

    render json: student_enrollments
  end
end
