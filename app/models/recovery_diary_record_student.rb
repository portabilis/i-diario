class RecoveryDiaryRecordStudent < ActiveRecord::Base
  belongs_to :recovery_diary_record
  belongs_to :student

  scope :ordered, -> { joins(:student).order(Student.arel_table[:name]) }

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
      maximum_score_for_school_term_recovery
    else
      maximum_score_for_final_recovery
    end
  end

  private

  def maximum_score_for_school_term_recovery
    if recovery_diary_record.classroom.exam_rule.recovery_type == RecoveryTypes::SPECIFIC
      recovery_exam_rule = recovery_diary_record.classroom
        .exam_rule
        .recovery_exam_rules
        .find do |recovery_exam_rule|
          recovery_exam_rule.steps.last.eql?(
            recovery_diary_record.school_term_recovery_diary_record
              .school_calendar_step
              .to_number
          )
        end

      recovery_exam_rule.maximum_score
    else
      recovery_diary_record.school_term_recovery_diary_record
        .school_calendar_step
        .test_setting.maximum_score
    end
  end

  def maximum_score_for_final_recovery
    recovery_diary_record.classroom.exam_rule.final_recovery_maximum_score
  end
end
