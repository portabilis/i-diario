class CoursesController < ApplicationController
  respond_to :json

  def index
    @courses = apply_scopes(Course).ordered
  end
end
