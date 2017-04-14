class Dashboard::TeacherWorkDoneChartController < ApplicationController
  def index
    render json: TeacherWorkDoneChartFetcher.new(params[:teacher_id], params[:school_calendar_step_id]).fetch!
  end
end
