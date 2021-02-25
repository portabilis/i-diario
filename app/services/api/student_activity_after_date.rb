module Api
  class StudentActivityAfterDate
    DAILY_NOTE = 'daily_note'.freeze
    CONCEPTUAL_EXAM = 'conceptual_exam'.freeze
    DESCRIPTIVE_EXAM = 'descriptive_exam'.freeze
    AVALIATION_EXEMPTION = 'avaliation_exemption'.freeze
    TRANSFER_NOTE = 'transfer_note'.freeze
    COMPLEMENTARY_EXAM = 'complementary_exam'.freeze
    GENERAL_DESCRIPTIVE_EXAM = 'general_descriptive_exam'.freeze
    AVALIATION_RECOVERY_DIARY_RECORD = 'recovery_diary_record_student'.freeze
    SCHOOL_TERM_RECOVERY_DIARY_RECORD = 'school_term_recovery_diary_record'.freeze
    OBSERVATION_DIARY_RECORD = 'observation_diary_record'.freeze

    def student_activities(student_id, date)
      activities_query(student_id, date)

      activities = []

      activities << build_hash(DAILY_NOTE, @daily_note.presence)
      activities << build_hash(CONCEPTUAL_EXAM, @conceptual_exam.presence)
      activities << build_hash(DESCRIPTIVE_EXAM, @descriptive_exam.presence)
      activities << build_hash(AVALIATION_EXEMPTION, @avaliation_exemption.presence)
      activities << build_hash(TRANSFER_NOTE, @transfer_note.presence)
      activities << build_hash(COMPLEMENTARY_EXAM, @complementary_exam.presence)
      activities << build_hash(GENERAL_DESCRIPTIVE_EXAM, @general_descriptive_exam.presence)
      activities << build_hash(AVALIATION_RECOVERY_DIARY_RECORD, @avaliation_recovery_diary_record.presence)
      activities << build_hash(SCHOOL_TERM_RECOVERY_DIARY_RECORD, @school_term_recovery_diary_record.presence)
      activities << build_hash(OBSERVATION_DIARY_RECORD, @observation_diary_record.presence)

      activities.compact
    end

    private

    def activities_query(student_id, date)
      @daily_note = DailyNoteStudent.joins(daily_note: [avaliation: :discipline])
                                    .by_student_id(student_id)
                                    .where("avaliations.test_date < '#{date}'")
                                    .pluck('disciplines.api_code')
                                    .uniq

      @conceptual_exam = ConceptualExam.joins(conceptual_exam_values: :discipline)
                                       .by_student_id(student_id)
                                       .where("recorded_at < '#{date}'")
                                       .pluck('disciplines.api_code')
                                       .uniq

      @descriptive_exam =
        DescriptiveExamStudent.joins(:descriptive_exam)
                              .joins('LEFT JOIN disciplines ON descriptive_exams.discipline_id = disciplines.id')
                              .pluck('disciplines.api_code')
                              .uniq

      @general_descriptive_exam = false

      if @descriptive_exam.any?(&:nil?)
        @general_descriptive_exam = true
        @descriptive_exam = @descriptive_exam.compact
      end

      @avaliation_exemption = AvaliationExemption.joins(avaliation: :discipline)
                                                 .by_student(student_id)
                                                 .where("avaliations.test_date < '#{date}'")
                                                 .pluck('disciplines.api_code')
                                                 .uniq

      @transfer_note = TransferNote.joins(:discipline)
                                   .where(student_id: student_id)
                                   .where("transfer_notes.recorded_at < '#{date}'")
                                   .pluck('disciplines.api_code')
                                   .uniq

      @complementary_exam = ComplementaryExamStudent.joins(complementary_exam: :discipline)
                                                    .by_student_id(student_id)
                                                    .where("complementary_exams.recorded_at < '#{date}'")
                                                    .pluck('disciplines.api_code')
                                                    .uniq

      @avaliation_recovery_diary_record =
        RecoveryDiaryRecordStudent.joins(recovery_diary_record: [:discipline, :avaliation_recovery_diary_record])
                                  .by_student_id(student_id)
                                  .where("recovery_diary_records.recorded_at < '#{date}'")
                                  .pluck('disciplines.api_code')
                                  .uniq

      @school_term_recovery_diary_record =
        RecoveryDiaryRecordStudent.joins(recovery_diary_record: [:discipline, :school_term_recovery_diary_record])
                                  .by_student_id(student_id)
                                  .where("school_term_recovery_diary_records.recorded_at < '#{date}'")
                                  .pluck('disciplines.api_code')
                                  .uniq

      @observation_diary_record =
        ObservationDiaryRecordNoteStudent.joins(observation_diary_record_note: [
                                                  observation_diary_record: :discipline
                                                ])
                                         .by_student_id(student_id)
                                         .where("observation_diary_records.date < '#{date}'")
                                         .pluck('disciplines.api_code')
                                         .uniq
    end

    def build_hash(type, activity)
      return if activity.blank?

      {
        'type': type,
        'disciplines': (activity if activity.is_a?(Array)),
        'general': (activity unless activity.is_a?(Array))
      }.delete_if { |_k, value| value.nil? }
    end
  end
end
