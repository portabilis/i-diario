class DailyNoteStatus < ActiveRecord::Base
  belongs_to :daily_note

  scope :by_status, lambda { |status| where(status: status) }

  def readonly?
    true
  end
end
