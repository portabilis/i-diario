class RecoveryDiaryRecordStudent < ActiveRecord::Base
  belongs_to :recovery_diary_record
  belongs_to :student

  scope :by_student_id, lambda { |student_id| where(student_id: student_id) }
  scope :by_recovery_diary_record_id, lambda { |recovery_diary_record_id| where(recovery_diary_record_id: recovery_diary_record_id) }

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
    elsif recovery_diary_record.final_recovery_diary_record.present?
      maximum_score_for_final_recovery
    elsif recovery_diary_record.avaliation_recovery_diary_record.present?
      maximum_score_for_avaliation_recovery
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

  def maximum_score_for_avaliation_recovery
    if avaliation.fix_tests?
      test_setting_test = TestSettingTest.find_by(id: avaliation.test_setting_test_id, test_setting_id: avaliation.test_setting_id)
      if test_setting_test.allow_break_up?
        avaliation.weight
      else
        test_setting_test.weight
      end
    else
      recovery_diary_record.avaliation_recovery_diary_record.avaliation.test_setting.maximum_score
    end
  end

  def avaliation
    recovery_diary_record.avaliation_recovery_diary_record.avaliation
  end
end
