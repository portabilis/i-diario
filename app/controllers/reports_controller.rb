class ReportsController < ApplicationController
  def attendance
    @attendance_report_form = AttendanceReportForm.new

    respond_to do |format|
      daily_frequencies = DailyFrequency.where(DailyFrequency.arel_table[:id].eq(1).or(DailyFrequency.arel_table[:id].eq(2)))

      format.html
      format.pdf do
        pdf = Attendance.build(daily_frequencies)
        send_data pdf.render, filename: "frequencia.pdf", type: "application/pdf", disposition: "inline"
      end
    end
  end
end


