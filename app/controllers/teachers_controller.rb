class TeachersController < ApplicationController
  def index
    @teachers = apply_scopes(Teacher)

    respond_with @teachers
  end
end
