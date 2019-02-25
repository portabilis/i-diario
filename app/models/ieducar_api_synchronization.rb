class IeducarApiSynchronization < ActiveRecord::Base
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

  scope :unnotified, -> { where(notified: false) }

  def self.completed_unnotified
    completed.unnotified.last
  end

  def self.last_error
    error.unnotified.last
  end

  def mark_as_error!(message, full_error_message='')
    self.status = ApiSynchronizationStatus::ERROR
    self.error_message = message
    self.full_error_message = full_error_message

    save(validate: false)
  end

  def mark_as_completed!
    update_attribute(:status, ApiSynchronizationStatus::COMPLETED)
  end

  def notified!
    update_column(:notified, true)
  end

  def set_job_id!(job_id)
    update_attribute(:job_id, job_id)
  end

  def running?
    number_of_checks = 3
    number_of_checks.times do
      return true if job_is_running?
    end

    false
  end

  def self.cancel_not_running_synchronizations(current_entity, options = {})
    restart = options.fetch(:restart, false)

    started.reject(&:running?).each do |sync|
      if restart
        job_id = IeducarSynchronizerWorker.perform_async(current_entity.id, sync.id)

        sync.set_job_id!(job_id)
      else
        sync.mark_as_error! I18n.t('ieducar_api_synchronization.public_error_feedback'),
                            I18n.t('ieducar_api_synchronization.private_error_feedback')
      end
    end
  end

  private

  def job_is_running?
    running = Sidekiq::Queue.new('default').find_job(job_id)
    running ||= Sidekiq::ScheduledSet.new.find_job(job_id)
    running ||= Sidekiq::RetrySet.new.find_job(job_id)

    if running.blank? && !Sidekiq::Workers.new.empty?
      Sidekiq::Workers.new.each do |_process_id, _thread_id, work|
        (running = work['payload']['jid'] == job_id) && break
      end
    end

    running
  end
end
