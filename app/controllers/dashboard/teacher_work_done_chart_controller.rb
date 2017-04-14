class Dashboard::TeacherWorkDoneChartController < ApplicationController
  def index
    render json: TeacherWorkDoneChartFetcher.new(classroom: current_user_classroom,
                                                 discipline: current_user_discipline,
                                                 school_calendar_step: params[:school_calendar_step_id]).fetch!
  end
end
