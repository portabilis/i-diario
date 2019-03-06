module LifeCycleTimeLoggable
  extend ActiveSupport::Concern

  def start!
    return if status == ApiSynchronizationStatus::STARTED

    with_lock do
      reset
      self.status = ApiSynchronizationStatus::STARTED
      self.started_at = Time.zone.now
      save!
    end
  end

  def end!
    return if status == ApiSynchronizationStatus::COMPLETED

    update(
      status: ApiSynchronizationStatus::COMPLETED,
      ended_at: Time.zone.now
    )
  end

  def reset
  end
end
