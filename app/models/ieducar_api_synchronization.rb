class IeducarApiSynchronization < ApplicationRecord
  acts_as_copy_target

  has_enumeration_for :status,
                      with: ApiSynchronizationStatus,
                      create_helpers: true,
                      create_scopes: true

  belongs_to :ieducar_api_configuration
  belongs_to :author, class_name: 'User'

  validates :ieducar_api_configuration, presence: true
  validates :ieducar_api_configuration_id, uniqueness: { scope: :status }, if: :started?

  delegate :to_api, to: :ieducar_api_configuration
  delegate :done_percentage, :started_at, :ended_at, to: :worker_batch, allow_nil: true

  scope :unnotified, -> { where(notified: false) }

  def worker_batch
    @worker_batch ||= WorkerBatch.where(
      main_job_class: 'IeducarSynchronizerWorker',
      main_job_id: job_id
    ).first
  end

  def time_running
    return unless started_at

    if ended_at
      ((ended_at - started_at) / 60.0).round
    else
      ((Time.current - started_at) / 60.0).round
    end
  end

  def self.average_time
    valid = completed.last(10).select(&:ended_at)

    valid.sum(&:time_running) / valid.size if valid.present?
  end

  def self.completed_unnotified
    completed.unnotified.last
  end

  def self.last_error
    error.unnotified.last
  end

  def mark_as_error!(message, full_error_message = '')
    self.status = ApiSynchronizationStatus::ERROR
    self.error_message = message
    self.full_error_message = full_error_message

    save(validate: false)
    worker_batch.mark_as_error! if worker_batch.present? && !worker_batch.error?
  end

  def mark_as_completed!
    update_last_synchronization_date

    update(status: ApiSynchronizationStatus::COMPLETED)
    worker_batch.try(:end!)
  end

  def notified!
    update_column(:notified, true)
  end

  def set_job_id!(job_id)
    update_attribute(:job_id, job_id)
  end

  def running?
    started? && job_is_running?
  end

  # Irá ver se o batch rodou até o fim. Se não rodou e está há mais de uma hora
  # sem updates, vai fazer um double check no sidekiq.
  def job_is_running?
    return false if worker_batch.completed?
    return true if worker_batch.updated_at > 1.hour.ago

    running = Sidekiq::Queue.new('default').find_job(job_id)
    running ||= Sidekiq::ScheduledSet.new.find_job(job_id)
    running ||= Sidekiq::RetrySet.new.find_job(job_id)
    running ||= Sidekiq::Workers.new.any? do |_process_id, _thread_id, work|
      work['payload']['jid'] == job_id
    end

    running.present?
  end

  def self.cancel_not_running_synchronizations(current_entity, options = {})
    restart = options.fetch(:restart, false)

    started.reject(&:running?).each do |sync|
      sync.mark_as_error! I18n.t('ieducar_api_synchronization.public_error_feedback'),
                          I18n.t('ieducar_api_synchronization.private_error_feedback')

      if restart
        configuration = IeducarApiConfiguration.current
        configuration.start_synchronization(sync.author, current_entity.id)
      end
    end
  end

  def update_last_synchronization_date
    IeducarApiConfiguration.current.update_synchronized_at!(started_at)
  end

  def error_by_user(user)
    sync_error = full_error_message if user.admin?
    sync_error = error_message if sync_error.blank?
    sync_error
  end
end
