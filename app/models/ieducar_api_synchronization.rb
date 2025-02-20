class IeducarApiSynchronization < ApplicationRecord
  acts_as_copy_target

  has_enumeration_for :status,
                      with: ApiSynchronizationStatus,
                      create_helpers: true,
                      create_scopes: true

  belongs_to :ieducar_api_configuration
  belongs_to :author, class_name: 'User'
  has_one :worker_batch, as: :stateable, dependent: :restrict_with_error

  validates :ieducar_api_configuration, presence: true
  validates :ieducar_api_configuration_id, uniqueness: { scope: :status }, if: :started?

  delegate :to_api, to: :ieducar_api_configuration
  delegate :done_percentage, :started_at, :ended_at, to: :worker_batch, allow_nil: true

  scope :unnotified, -> { where(notified: false) }
  scope :by_full_synchronizations,    -> { where(full_synchronization: true) }
  scope :by_partial_synchronizations, -> { where(full_synchronization: false) }
  scope :ordered, -> { order(id: :desc) }

  def time_running
    return 0 unless started_at

    if ended_at
      ((ended_at - started_at) / 60.0).round
    else
      ((Time.current - started_at) / 60.0).round
    end
  end

  def self.average_time(scope, limit)
    subquery = scope
                .completed
                .joins(:worker_batch)
                .order('ieducar_api_synchronizations.id DESC')
                .limit(limit)
                .select('worker_batches.started_at, worker_batches.ended_at')

    from("(#{subquery.to_sql}) AS subquery")
      .select("ROUND(AVG(EXTRACT(EPOCH FROM subquery.ended_at - subquery.started_at) / 60.0))::integer AS avg_time")
      .take
      &.avg_time
  end

  def self.average_time_by_full_synchronizations
    Rails.cache.fetch("ieducar_api_synchronization/average_time_by_full_synchronizations/entity-#{Entity.current}", expires_in: 24.hour) do
    average_time(by_full_synchronizations, 5)
    end
  end

  def self.average_time_by_partial_synchronizations
    Rails.cache.fetch("ieducar_api_synchronization/average_time_by_partial_synchronizations/entity-#{Entity.current}", expires_in: 24.hour) do
    average_time(by_partial_synchronizations, 10)
    end
  end

  def average_time
    if full_synchronization?
      IeducarApiSynchronization.average_time_by_full_synchronizations
    else
      IeducarApiSynchronization.average_time_by_partial_synchronizations
    end
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

  def self.cancel_locked_synchronizations(current_entity, options = {})
    restart = options.fetch(:restart, false)

    started.each do |sync|
      last_author = sync.author
      if sync.time_running > sync.average_time * 3
        sync.mark_as_error! I18n.t('ieducar_api_synchronization.timedout'),
                            I18n.t('ieducar_api_synchronization.timedout')

        if restart
          configuration = IeducarApiConfiguration.current
          configuration.start_synchronization(sync.author, current_entity.id)
        end
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
