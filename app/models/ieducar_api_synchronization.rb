class IeducarApiSynchronization < ActiveRecord::Base
  acts_as_copy_target

  has_enumeration_for :status, with: ApiSynchronizationStatus, create_helpers: true,
    create_scopes: true

  belongs_to :ieducar_api_configuration
  belongs_to :author, class_name: "User"

  validates :ieducar_api_configuration, presence: true
  validates :ieducar_api_configuration_id, uniqueness: { scope: :status }, if: :started?

  delegate :to_api, to: :ieducar_api_configuration
  delegate :started_at, :ended_at, to: :worker_batch, allow_nil: true

  scope :unnotified, -> { where(notified: false) }

  def worker_batch
    @worker_batch ||= WorkerBatch.where(
      main_job_class: 'IeducarSynchronizerWorker',
      main_job_id: job_id
    ).first
  end

  def time_running
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
    self.completed.unnotified.last
  end

  def self.last_error
    self.error.unnotified.last
  end

  def mark_as_error!(message, full_error_message='')
    self.status = ApiSynchronizationStatus::ERROR
    self.error_message = message
    self.full_error_message = full_error_message
    save(validate: false)
    worker_batch.try(:end!)
  end

  def mark_as_completed!
    update_attribute(:status, ApiSynchronizationStatus::COMPLETED)
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

  # Primeiro verifica no Sidekiq::Status;
  #
  # Caso não tenha dado lá, irá verificar direto no Sidekiq. Isso é necessário
  # pois o Sidekiq::Status não está estável o sificiente.
  def job_is_running?
    if Sidekiq::Status::get_all(job_id)
      return Sidekiq::Status::status(job_id).in?([:queued, :working, :retrying, :interrupted])
    end

    running = Sidekiq::Queue.new('default').find_job(job_id) ||
              Sidekiq::ScheduledSet.new.find_job(job_id) ||
              Sidekiq::RetrySet.new.find_job(job_id)

    if running.blank?
      Sidekiq::Workers.new.each do |_process_id, _thread_id, work|
        (running = work['payload']['jid'] == job_id) && break
      end
    end

    running
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
end
