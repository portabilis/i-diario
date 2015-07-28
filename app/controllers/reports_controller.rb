class ReportsController < ApplicationController
  def attendance
    @attendance_report_form = AttendanceReportForm.new

    respond_to do |format|
      daily_frequencies = DailyFrequency.where(classroom_id: 68)

      format.html
      format.pdf do
        pdf = Attendance.build(current_entity_configuration, current_teacher, daily_frequencies)
        send_data pdf.render, filename: "frequencia.pdf", type: "application/pdf", disposition: "inline"
      end
    end
  end
end


