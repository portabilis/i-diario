class SchoolCalendarClassroomStepsController < ApplicationController
  def show
    @school_calendar_classroom_step = SchoolCalendarClassroomStep.find(params[:id]).localized

    render json: @school_calendar_classroom_step
  end

  def index
    @school_calendar_classroom_steps = apply_scopes(SchoolCalendarClassroomStep).ordered

    steps = []
    @school_calendar_classroom_steps.each do |school_calendar_classroom_step|
      steps << {
        id: school_calendar_classroom_step.id,
        school_term: school_calendar_classroom_step.to_s
      }
    end

    render json: steps
  end
end
