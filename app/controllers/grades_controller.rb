class GradesController < ApplicationController
  respond_to :json

  def index
    if params[:filter].present? && params[:filter][:by_courses].present?
      params[:filter][:by_course] = params[:filter][:by_courses].split(',')
      params[:filter].delete(:by_courses)
    end

    @grades = apply_scopes(Grade).ordered
  end
end
