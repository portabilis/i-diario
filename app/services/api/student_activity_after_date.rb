module Api
  class StudentActivityAfterDate
    def student_activities(student_id, date)
      activities_query(student_id, date)

      retorno = []

      retorno << build_hash(DAILY_NOTE, @daily_note) if @daily_note.present?
      retorno << build_hash(CONCEPTUAL_EXAM, @conceptual_exam) if @conceptual_exam.present?
      retorno << build_hash(DESCRIPTIVE_EXAM, @descriptive_exam) if @descriptive_exam.present?
      retorno << build_hash(AVALIATION_EXEMPTION, @avaliation_exemption) if @avaliation_exemption.present?
      retorno << build_hash(TRANSFER_NOTE, @transfer_note) if @transfer_note.present?
      retorno << build_hash(COMPLEMENTARY_EXAM, @complementary_exam) if @complementary_exam.present?
      retorno << build_hash(GENERAL_DESCRIPTIVE_EXAM, @general_descriptive_exam) if @general_descriptive_exam
      if @avaliation_recovery_diary_record.present?
        retorno << build_hash(AVALIATION_RECOVERY_DIARY_RECORD, @avaliation_recovery_diary_record)
      end
      if @school_term_recovery_diary_record.present?
        retorno << build_hash(SCHOOL_TERM_RECOVERY_DIARY_RECORD, @school_term_recovery_diary_record)
      end
      if @observation_diary_record.present?
        retorno << build_hash(OBSERVATION_DIARY_RECORD, @observation_diary_record)
      end
      retorno
    end

    private

    DAILY_NOTE = I18n.t('activerecord.models.daily_note.one')
    CONCEPTUAL_EXAM = I18n.t('activerecord.models.conceptual_exam.one')
    DESCRIPTIVE_EXAM = I18n.t('activerecord.models.descriptive_exam.one')
    AVALIATION_EXEMPTION = I18n.t('activerecord.models.avaliation_exemption.one')
    TRANSFER_NOTE = I18n.t('activerecord.models.transfer_note.one')
    COMPLEMENTARY_EXAM = I18n.t('activerecord.models.complementary_exam.one')
    GENERAL_DESCRIPTIVE_EXAM = I18n.t('activerecord.models.descriptive_exam.one')
    AVALIATION_RECOVERY_DIARY_RECORD = I18n.t('activerecord.models.recovery_diary_record_student.one')
    SCHOOL_TERM_RECOVERY_DIARY_RECORD = I18n.t('activerecord.models.school_term_recovery_diary_record.one')
    OBSERVATION_DIARY_RECORD = I18n.t('activerecord.models.observation_diary_record.one')

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

      @descriptive_exam = DescriptiveExamStudent.joins(:descriptive_exam)
                                                .joins('LEFT JOIN disciplines
                                                        ON descriptive_exams.discipline_id = disciplines.id')
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

      @transfer_note = TransferNote.joins(:student, :discipline)
                                   .where(student_id: student_id)
                                   .where("transfer_notes.recorded_at < '#{date}'")
                                   .pluck('disciplines.api_code')
                                   .uniq

      @complementary_exam = ComplementaryExamStudent.joins(complementary_exam: :discipline)
                                                    .by_student_id(student_id)
                                                    .where("complementary_exams.recorded_at < '#{date}'")
                                                    .pluck('disciplines.api_code')
                                                    .uniq

      @avaliation_recovery_diary_record = RecoveryDiaryRecordStudent.joins(recovery_diary_record:
                                                                    [:discipline,
                                                                     :avaliation_recovery_diary_record])
                                                                    .by_student_id(student_id)
                                                                    .where("recovery_diary_records.recorded_at <
                                                                            '#{date}'
                                                                    ")
                                                                    .pluck('disciplines.api_code')
                                                                    .uniq

      @school_term_recovery_diary_record = RecoveryDiaryRecordStudent.joins(recovery_diary_record:
                                                                     [:discipline,
                                                                      :school_term_recovery_diary_record])
                                                                     .by_student_id(student_id)
                                                                     .where("
                                                                     school_term_recovery_diary_records.recorded_at
                                                                     < '#{date}'
                                                                     ")
                                                                     .pluck('disciplines.api_code')
                                                                     .uniq

      @observation_diary_record = ObservationDiaryRecordNoteStudent.joins(observation_diary_record_note:
                                                                   [observation_diary_record: :discipline])
                                                                   .by_student_id(student_id)
                                                                   .where("observation_diary_records.date
                                                                          < '#{date}'")
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
