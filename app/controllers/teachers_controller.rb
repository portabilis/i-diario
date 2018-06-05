class TeachersController < ApplicationController
  def index
    if params[:find_by_current_year]
      year = current_school_calendar.try(:year)
    end

    @teachers = apply_scopes(Teacher)
    @teachers = @teachers.by_year(year) if year

    respond_with @teachers
  end
end
