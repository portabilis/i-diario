class SidekiqMonitorController < ActionController::Base
  def processes_status
    status = SidekiqMonitor.processses_running? ? SidekiqStatus::OK : SidekiqStatus::NOT_OK

    render text: status
  end
end
