class Dashboard::TeacherNextAvaliationsController < ApplicationController
  def index
    render json: TeacherNextAvaliationsFetcher.new(teacher: current_teacher,
                                                   classroom: current_user_classroom,
                                                   discipline: current_user_discipline).fetch!
  end
end