class DashboardController < ApplicationController
  def index
    @teacher_avaliations = TeacherNextAvaliationsFetcher.new(current_teacher).fetch!
  end
end
