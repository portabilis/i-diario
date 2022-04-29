class SystemNotification < ActiveRecord::Base
  SOURCES_TO_OPEN_IN_NEW_TAB = [
    'InfrequencyTracking'
  ].freeze

  has_many :targets, class_name: "SystemNotificationTarget", inverse_of: :system_notification

  belongs_to :source, polymorphic: true

  validates :title, :description, presence: true
  validates :source, presence: true, unless: :is_generic?

  scope :ordered, -> { order(created_at: :desc) }
  scope :not_in, lambda { |ids| where(arel_table[:id].not_in(ids)) }

  def open_link_in_new_tab?
    SOURCES_TO_OPEN_IN_NEW_TAB.include?(source_type)
  end

  def is_generic?
    generic
  end
end
