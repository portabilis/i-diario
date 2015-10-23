class SchoolCalendarStepsController < ApplicationController
  def show
    @school_calendar_step = SchoolCalendarStep.find(params[:id]).localized

    render json: @school_calendar_step
  end
end
