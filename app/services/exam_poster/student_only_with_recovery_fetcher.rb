module ExamPoster
  class StudentOnlyWithRecoveryFetcher < Base
    attr_reader :recoveries
    attr_reader :scores

    def initialize(students_with_daily_note, school_term_recovery_diary_record)
      @recoveries = []
      @scores = []
      @students_with_daily_note = students_with_daily_note
      @school_term_recovery_diary_record = school_term_recovery_diary_record
    end

    def fetch!
      @recoveries = fetch_school_term_recovery_score
      @scores = Student.where(id: @recoveries.map(&:student_id)) if @recoveries.try(:any?)
    end

    private

    def fetch_school_term_recovery_score
      return unless @school_term_recovery_diary_record

      student_ids = @students_with_daily_note.scores.map(&:id)
      student_recoveries = RecoveryDiaryRecordStudent.by_recovery_diary_record_id(
        @school_term_recovery_diary_record.recovery_diary_record_id
      )
      student_recoveries.where.not(student_id: student_ids)
    end
  end
end
