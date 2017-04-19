class Dashboard::TeacherPendingAvaliationsController < ApplicationController
  def index
    render json: TeacherPendingAvaliationsFetcher.new(teacher: current_teacher,
                                                      classroom: current_user_classroom,
                                                      discipline: current_user_discipline,
                                                      school_calendar_step: params[:school_calendar_step_id]).fetch!
  end
end
