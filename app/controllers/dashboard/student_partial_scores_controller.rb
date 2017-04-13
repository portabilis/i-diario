class Dashboard::StudentPartialScoresController < ApplicationController
  def index
    render json: StudentPartialScoresFetcher.new(params[:student_id], params[:school_calendar_step_id]).fetch!
  end
end
