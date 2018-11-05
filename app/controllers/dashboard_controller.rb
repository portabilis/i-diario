class DashboardController < ApplicationController

  before_filter :load_parent_dashboard_info, only: :index, if: :current_user_is_parent?

  def index
    fill_in_school_calendar_select_options
    fetch_current_school_calendar_step if @school_calendar_steps_options.any?
  end

  def load_parent_dashboard_info
    @panels = ParentDashboardBuilder.new(current_user, Date.current).build
  end

  private

  def fill_in_school_calendar_select_options
    @school_calendar_steps_options = []
    current_school_calendar_steps.each do |school_calendar_step|
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

  def current_school_calendar_steps
    current_school_calendar.try(:steps) || []
  end
end
