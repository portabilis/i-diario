class RecoveryDiaryRecordStudent < ActiveRecord::Base
  belongs_to :recovery_diary_record
  belongs_to :student

  validates :recovery_diary_record, presence: true
  validates(
    :score,
    numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: lambda { |r| r.maximum_score }
    },
    allow_blank: true
  )

  def maximum_score
    if recovery_diary_record.school_term_recovery_diary_record.present?
      recovery_diary_record.school_term_recovery_diary_record
        .school_calendar_step
        .test_setting.maximum_score
    end
  end
end
