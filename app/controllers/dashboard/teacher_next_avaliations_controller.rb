class Dashboard::TeacherNextAvaliationsController < ApplicationController
  def show
    render json: TeacherNextAvaliationsFetcher.new(params[:id]).fetch!
  end
end