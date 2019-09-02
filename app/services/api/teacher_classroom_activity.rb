module Api
  class TeacherClassroomActivity
    def initialize(teacher_id, classroom_id)
      @teacher_id = teacher_id
      @classroom_id = classroom_id
      @user_id = User.where(teacher_id: @teacher_id).first
    end

    def any_activity?
      return false if @user_id.blank?

      return true if DailyNote
                     .by_classroom_id(@classroom_id)
                     .by_teacher_id(@teacher_id)
                     .joins("INNER JOIN audits ON audits.auditable_id = daily_notes.id AND audits.auditable_type = 'DailyNote'")
                     .where('audits.user_id' => @user_id)
                     .exists?

      return true if DailyFrequency.by_classroom_id(@classroom_id)
                     .by_teacher_id(@teacher_id)
                     .joins("INNER JOIN audits ON audits.auditable_id = daily_frequencies.id AND audits.auditable_type = 'DailyFrequency'")
                     .where('audits.user_id' => @user_id)
                     .exists?

      return true if ConceptualExam
                     .by_classroom_id(@classroom_id)
                     .by_teacher(@teacher_id)
                     .joins("INNER JOIN audits ON audits.auditable_id = conceptual_exams.id AND audits.auditable_type = 'ConceptualExam'")
                     .where('audits.user_id' => @user_id)
                     .exists?

      return true if DescriptiveExam
                     .by_classroom_id(@classroom_id)
                     .by_teacher_id(@teacher_id)
                     .joins("INNER JOIN audits ON audits.auditable_id = descriptive_exams.id AND audits.auditable_type = 'DescriptiveExam'")
                     .where('audits.user_id' => @user_id)
                     .exists?

      return true if RecoveryDiaryRecord
                     .by_classroom_id(@classroom_id)
                     .by_teacher_id(@teacher_id)
                     .joins("INNER JOIN audits ON audits.auditable_id = recovery_diary_records.id AND audits.auditable_type = 'RecoveryDiaryRecord'")
                     .where('audits.user_id' => @user_id)
                     .exists?

      return true if TransferNote
                     .by_classroom_id(@classroom_id)
                     .by_teacher_id(@teacher_id)
                     .joins("INNER JOIN audits ON audits.auditable_id = transfer_notes.id AND audits.auditable_type = 'TransferNote'")
                     .where('audits.user_id' => @user_id)
                     .exists?

      return true if ComplementaryExam
                     .by_classroom_id(@classroom_id)
                     .by_teacher_id(@teacher_id)
                     .joins("INNER JOIN audits ON audits.auditable_id = complementary_exams.id AND audits.auditable_type = 'ComplementaryExam'")
                     .where('audits.user_id' => @user_id)
                     .exists?

      false
    end
  end
end
