class IeducarApiExamPosting < ActiveRecord::Base
  acts_as_copy_target

  has_enumeration_for :post_type, with: ApiPostingTypes,  create_scopes: true
  has_enumeration_for :status,    with: ApiPostingStatus, create_helpers: true,
                                                          create_scopes: true

  belongs_to :ieducar_api_configuration
  belongs_to :school_calendar_step
  belongs_to :school_calendar_classroom_step
  belongs_to :author, class_name: 'User'
  belongs_to :teacher

  has_one :worker_batch, as: :stateable
  has_many :notices, as: :noticeable

  validates :ieducar_api_configuration, presence: true
  validates :school_calendar_step, presence: true, unless: :school_calendar_classroom_step
  validates :school_calendar_classroom_step, presence: true, unless: :school_calendar_step

  delegate :to_api, to: :ieducar_api_configuration

  def warning_message
    super.presence || notices.texts
  end

  def self.completed
    self.completed.last
  end

  def self.errors
    self.error.last
  end

  def self.warnings
    Notice.all.merge(self.all).texts
  end

  def synchronization_in_progress?
    status == ApiSynchronizationStatus::STARTED
  end

  def mark_as_error!(message, full_error_message='')
    update_columns(
      status: ApiSynchronizationStatus::ERROR,
      error_message: message,
      full_error_message: full_error_message,
    )
  end

  def mark_as_warning!(message = nil)
    transaction do
      add_warning!(message) if message
      update_attribute(:status, ApiSynchronizationStatus::WARNING)
    end
  end

  def add_warning!(messages)
    Array(messages).each do |message|
      notices.create(kind: NoticeTypes::WARNING, text: message)
    end
  end

  def mark_as_completed!(message)
    update_columns(
      status: ApiSynchronizationStatus::COMPLETED,
      message: message
    )
  end

  def done_percentage
    return 100 if !synchronization_in_progress?
    return 0   if worker_batch.blank?

    worker_batch.done_percentage
  end

  def step
    self.school_calendar_classroom_step || self.school_calendar_step
  end
end
