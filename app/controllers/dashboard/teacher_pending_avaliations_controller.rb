class Dashboard::TeacherPendingAvaliationsController < ApplicationController
  def index
    render json: TeacherPendingAvaliationsFetcher.new(params[:teacher_id], params[:school_calendar_step_id]).fetch!
  end
end
