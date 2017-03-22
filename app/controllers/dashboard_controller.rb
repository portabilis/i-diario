class DashboardController < ApplicationController
  before_action :require_current_school_calendar

  def index
    fill_in_school_calendar_select_options
    fetch_current_school_calendar_step
  end

  private

  def fill_in_school_calendar_select_options
    @school_calendar_steps = current_school_calendar.steps
    @school_calendar_steps_options = []
    @school_calendar_steps.each do |school_calendar_step|
      option = []
      option << school_calendar_step.to_s
      option << school_calendar_step.id
      @school_calendar_steps_options << option
    end
  end

  def fetch_current_school_calendar_step
    @current_school_calendar_step = current_school_calendar.step(Time.zone.today).try(:id)
  end

  def current_school_calendar
    CurrentSchoolCalendarFetcher.new(current_user_unity, nil).fetch
  end
end
