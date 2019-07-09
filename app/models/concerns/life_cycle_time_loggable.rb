module LifeCycleTimeLoggable
  extend ActiveSupport::Concern

  included do
    has_enumeration_for :status, with: ApiSynchronizationStatus, create_helpers: true
  end

  def start!
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

  def reset; end
end
