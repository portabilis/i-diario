class AttendanceRecordReportByStudentsController < ApplicationController
  before_action :require_current_classroom
  before_action :require_current_teacher

  def form

  end
end
