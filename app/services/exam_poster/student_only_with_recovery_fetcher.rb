module ExamPoster
  class StudentOnlyWithRecoveryFetcher < Base
    attr_reader :recoveries
    attr_reader :scores

    def initialize(teacher, classroom, discipline, step, school_term_recovery_diary_record)
      @teacher = teacher
      @classroom = classroom
      @discipline = discipline
      @step = step
      @recoveries = []
      @scores = []
      @school_term_recovery_diary_record = school_term_recovery_diary_record
    end

    def fetch!
      @recoveries = fetch_school_term_recovery_score(@classroom, @discipline, @step)
      @scores = Student.where(id: @recoveries.map(&:student_id)) if @recoveries.try(:any?)
    end

    private

    def fetch_school_term_recovery_score(classroom, discipline, step)
      return unless @school_term_recovery_diary_record

      student_ids = students_with_daily_note.map(&:id)
      student_recoveries = RecoveryDiaryRecordStudent.by_recovery_diary_record_id(
        school_term_recovery_diary_record.recovery_diary_record_id
      )
      student_recoveries.where.not(student_id: student_ids)
    end

    def students_with_daily_note
      teacher_score_fetcher = TeacherScoresFetcher.new(@teacher, @classroom, @discipline, @step)
      teacher_score_fetcher.fetch!

      teacher_score_fetcher.scores
    end
  end
end
