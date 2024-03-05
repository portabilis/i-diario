class Dashboard::TeacherPendingAvaliationsController < ApplicationController
  before_action :require_current_teacher
  before_action :require_current_classroom

  def index
    render json: TeacherPendingAvaliationsFetcher.new(teacher: current_teacher,
                                                      classroom: current_user_classroom,
                                                      discipline: current_user_discipline,
                                                      school_calendar_step: params[:school_calendar_step_id]).fetch!
  end
end
