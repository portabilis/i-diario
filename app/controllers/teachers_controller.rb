class TeachersController < ApplicationController
  def index
    if params[:find_by_current_year]
      year = current_school_calendar.try(:year)
    end

    @teachers = apply_scopes(Teacher).order_by_name
    @teachers = @teachers.by_year(year) if year

    respond_with @teachers
  end

  def select2
    teachers = apply_scopes(Teacher).order_by_name.uniq

    render json: teachers, each_serializer: Select2TeachersSerializer, root: 'results'
  end
end
