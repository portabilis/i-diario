module ExamPoster
  class StudentOnlyWithRecoveryFetcher < Base
    attr_reader :recoveries

    def initialize(teacher, classroom, discipline, step)
      @teacher = teacher
      @classroom = classroom
      @discipline = discipline
      @step = step
      @recoveries = []
    end

    def fetch!
      @recoveries = fetch_school_term_recovery_score(@classroom, @discipline, @step)
    end

    private

    def fetch_school_term_recovery_score(classroom, discipline, step)
      school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.by_classroom_id(classroom)
                                                                       .by_discipline_id(discipline)
                                                                       .by_step_id(classroom, step.id)
                                                                       .first

      return unless school_term_recovery_diary_record

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
