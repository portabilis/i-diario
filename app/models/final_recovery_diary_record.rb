class FinalRecoveryDiaryRecord < ActiveRecord::Base
  include Audit

  acts_as_copy_target

  audited
  has_associated_audits
  
  belongs_to :recovery_diary_record, dependent: :destroy
  belongs_to :school_calendar

  validates :recovery_diary_record, presence: true
  validates :school_calendar, presence: true
end
