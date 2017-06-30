class ObservationRecordReportController < ApplicationController
  before_action :require_current_teacher
  before_action :require_current_school_calendar

  def form
    @observation_record_report_form = ObservationRecordReportForm.new(
      teacher_id: current_teacher.id,
      unity_id: current_user_unity.id,
      start_at: Time.zone.today,
      end_at: Time.zone.today
    ).localized
  end

  def report
    @observation_record_report_form = ObservationRecordReportForm.new(
      resource_params
    )
    .localized

    if @observation_record_report_form.valid?
      observation_record_report = ObservationRecordReport.new(
          current_entity_configuration,
          @observation_record_report_form
        )
        .build

      send_data(
        observation_record_report.render,
        filename: 'registro-de-frequencia.pdf',
        type: 'application/pdf',
        disposition: 'inline'
      )
    else
      clear_invalid_dates
      render :form
    end
  end

  private

  def resource_params
    params.require(:observation_record_report_form).permit(
      :teacher_id,
      :unity_id,
      :classroom_id,
      :discipline_id,
      :start_at,
      :end_at
    )
  end

  def clear_invalid_dates
    begin
      resource_params[:start_at].to_date
    rescue ArgumentError
      @observation_record_report_form.start_at = ''
    end

    begin
      resource_params[:end_at].to_date
    rescue ArgumentError
      @observation_record_report_form.end_date = ''
    end
  end
end
