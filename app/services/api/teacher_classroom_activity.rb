module Api
  class TeacherClassroomActivity
    def initialize(teacher_id, classroom_id)
      @teacher_id = teacher_id
      @classroom_id = classroom_id
      @user_id = User.find_by(teacher_id: @teacher_id)
    end

    def any_activity?
      return false if @user_id.blank?

      return true if DailyNote
                     .by_classroom_id(@classroom_id)
                     .by_teacher_id(@teacher_id)
                     .joins(join_audits('daily_notes.id', 'DailyNote'))
                     .where('audits.user_id' => @user_id)
                     .exists?

      return true if DailyFrequency
                     .by_classroom_id(@classroom_id)
                     .by_teacher_classroom_id(@teacher_id, @classroom_id)
                     .joins(join_audits('daily_frequencies.id', 'DailyFrequency'))
                     .where('audits.user_id' => @user_id)
                     .exists?

      return true if ConceptualExam
                     .by_classroom_id(@classroom_id)
                     .by_teacher(@teacher_id)
                     .joins(join_audits('conceptual_exams.id', 'ConceptualExam'))
                     .where('audits.user_id' => @user_id)
                     .exists?

      return true if DescriptiveExam
                     .by_classroom_id(@classroom_id)
                     .by_teacher_id(@teacher_id)
                     .joins(join_audits('descriptive_exams.id', 'DescriptiveExam'))
                     .where('audits.user_id' => @user_id)
                     .exists?

      return true if RecoveryDiaryRecord
                     .by_classroom_id(@classroom_id)
                     .by_teacher_id(@teacher_id)
                     .joins(join_audits('recovery_diary_records.id', 'RecoveryDiaryRecord'))
                     .where('audits.user_id' => @user_id)
                     .exists?

      return true if TransferNote
                     .by_classroom_id(@classroom_id)
                     .by_teacher_id(@teacher_id)
                     .joins(join_audits('transfer_notes.id', 'TransferNote'))
                     .where('audits.user_id' => @user_id)
                     .exists?

      return true if ComplementaryExam
                     .by_classroom_id(@classroom_id)
                     .by_teacher_id(@teacher_id)
                     .joins(join_audits('complementary_exams.id', 'ComplementaryExam'))
                     .where('audits.user_id' => @user_id)
                     .exists?

      false
    end

    private

    def join_audits(auditable_id, auditable_type)
      <<-SQL
        INNER JOIN audits
          ON audits.auditable_id = #{auditable_id} AND audits.auditable_type = '#{auditable_type}'
      SQL
    end
  end
end
