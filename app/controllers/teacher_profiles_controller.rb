class TeacherProfilesController < ApplicationController
  def index
    filters = params[:filter].slice(:year, :unity_id)

    teacher_profiles = TeacherProfilesOptionsGenerator.new(current_user, filters[:year], filters[:unity_id]).run!

    render json: teacher_profiles.as_json
  end
end
