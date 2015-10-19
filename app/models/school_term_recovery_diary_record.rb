class SchoolTermRecoveryDiaryRecord < ActiveRecord::Base
  include Audit
  
  acts_as_copy_target

  audited
  has_associated_audits

  belongs_to :recovery_diary_record, dependent: :destroy
  belongs_to :school_calendar_step

  validates :recovery_diary_record, presence: true
  validates :school_calendar_step, presence: true
end
