class SystemNotificationTarget < ApplicationRecord
  belongs_to :system_notification
  belongs_to :user

  validates :system_notification, :user, presence: true

  scope :read, -> { where(arel_table[:read].eq(true)) }

  def self.read!
    where(read: false).update_all(read: true)
  end
end
