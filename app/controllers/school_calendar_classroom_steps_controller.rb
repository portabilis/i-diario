class SchoolCalendarClassroomStepsController < ApplicationController
  def show
    @school_calendar_classroom_step = SchoolCalendarClassroomStep.find(params[:id]).localized

    render json: @school_calendar_classroom_step
  end
end
