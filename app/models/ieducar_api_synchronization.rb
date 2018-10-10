class IeducarApiSynchronization < ActiveRecord::Base
  acts_as_copy_target

  has_enumeration_for :status, with: ApiSynchronizationStatus, create_helpers: true,
    create_scopes: true

  belongs_to :ieducar_api_configuration
  belongs_to :author, class_name: "User"

  validates :ieducar_api_configuration, presence: true
  validates :ieducar_api_configuration_id, uniqueness: { scope: :status }, if: :started?

  delegate :to_api, to: :ieducar_api_configuration

  scope :unnotified, -> { where(notified: false) }

  def self.completed_unnotified
    self.completed.unnotified.last
  end

  def self.last_error
    self.error.unnotified.last
  end

  def mark_as_error!(message, full_error_message='')
    update_columns(
      status: ApiSynchronizationStatus::ERROR,
      error_message: message,
      full_error_message: full_error_message,
    )
  end

  def mark_as_completed!
    update_column(:status, ApiSynchronizationStatus::COMPLETED)
  end

  def notified!
    update_column(:notified, true)
  end

  def set_job_id!(job_id)
    update_attribute(:job_id, job_id)
  end

  def running?
    running = Sidekiq::Queue.new('default').find_job(job_id) ||
      Sidekiq::ScheduledSet.new.find_job(job_id) ||
      Sidekiq::RetrySet.new.find_job(job_id)

    if Sidekiq::Workers.new.size > 0
      Sidekiq::Workers.new.each do |process_id, thread_id, work|
        (running = work['payload']['jid'] == job_id) && break
      end
    end

    running
  end
end
