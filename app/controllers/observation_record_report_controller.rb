class ObservationRecordReportController < ApplicationController
  before_action :require_current_teacher

  def form
    @observation_record_report_form = ObservationRecordReportForm.new(
      teacher_id: current_teacher.id,
      unity_id: current_unity.id,
      start_at: Time.zone.today,
      end_at: Time.zone.today,
      current_user_id: current_user.id
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
        send_pdf(t("routes.observation_record"), observation_record_report.render)
    else
      clear_invalid_dates
      render :form
    end
  end

  def unities
    if current_user.current_user_role.try(:role_administrator?)
      Unity.ordered
    else
      [current_user_unity]
    end
  end
  helper_method :unities

  private

  def resource_params
    params.require(:observation_record_report_form).permit(
      :teacher_id,
      :unity_id,
      :classroom_id,
      :discipline_id,
      :start_at,
      :end_at,
      :current_user_id
    )
  end

  def clear_invalid_dates
    start_at = resource_params[:start_at]
    end_at = resource_params[:end_at]

    @observation_record_report_form.start_at = '' unless start_at.try(:to_date)
    @observation_record_report_form.end_at = '' unless end_at.try(:to_date)
  end
end
