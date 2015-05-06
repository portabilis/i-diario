class DailyFrequencyStudent < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :daily_frequency, except: :daily_frequency_id

  belongs_to :daily_frequency
  belongs_to :student

  validates :student, :daily_frequency, presence: true
end
