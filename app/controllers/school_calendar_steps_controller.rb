class SchoolCalendarStepsController < ApplicationController
  def show
    @school_calendar_step = SchoolCalendarStep.find(params[:id]).localized

    render json: @school_calendar_step
  end

  def index
    @school_calendar_steps = apply_scopes(SchoolCalendarStep).ordered

    steps = []
    @school_calendar_steps.each do |school_calendar_step|
      steps << {
        id: school_calendar_step.id,
        school_term: school_calendar_step.to_s
      }
    end

    render json: steps
  end
end
