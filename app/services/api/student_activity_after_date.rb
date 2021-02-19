module Api
  class StudentActivityAfterDate
    def initialize(student_id, date)
      @student_id = student_id
      @date = date
    end

    def has_activities
      daily_note = DailyNoteStudent.joins(daily_note: [avaliation: :discipline])
                                   .by_student_id(@student_id)
                                   .where("avaliations.test_date < '#{@date}'")
                                   .pluck('disciplines.api_code')
                                   .uniq

      conceptual_exam = ConceptualExam.joins(conceptual_exam_values: :discipline)
                                      .by_student_id(@student_id)
                                      .where("recorded_at < '#{@date}'")
                                      .pluck('disciplines.api_code')
                                      .uniq  

      descriptive_exam = DescriptiveExamStudent.joins(:descriptive_exam)
                                               .joins("LEFT JOIN disciplines ON descriptive_exams.discipline_id = disciplines.id")
                                               .pluck('disciplines.api_code')
                                               .uniq
      descriptive_exam[descriptive_exam.index(nil)] = 'Geral'

      avaliation_exemption = AvaliationExemption.joins(avaliation: :discipline)
                                                .by_student(@student_id)
                                                .where("avaliations.test_date < '#{@date}'")
                                                .pluck('disciplines.api_code')
                                                .uniq

      transfer_note = TransferNote.joins(:student, :discipline)
                                  .where(student_id: @student_id)
                                  .where("transfer_notes.recorded_at < '#{@date}'")
                                  .pluck('disciplines.api_code')
                                  .uniq

      complementary_exam = ComplementaryExamStudent.joins(complementary_exam: :discipline)
                                                   .by_student_id(@student_id)
                                                   .where("complementary_exams.recorded_at < '#{@date}'")
                                                   .pluck('disciplines.api_code')
                                                   .uniq

      avaliation_recovery_diary_record = RecoveryDiaryRecordStudent.joins(recovery_diary_record: [:discipline, :avaliation_recovery_diary_record])
                                                                   .by_student_id(@student_id)
                                                                   .where("recovery_diary_records.recorded_at < '#{@date}'")
                                                                   .pluck('disciplines.api_code')
                                                                   .uniq

      school_term_recovery_diary_record = RecoveryDiaryRecordStudent.joins(recovery_diary_record: [:discipline, :school_term_recovery_diary_record])
                                                                    .by_student_id(@student_id)
                                                                    .where("school_term_recovery_diary_records.recorded_at < '#{@date}'")
                                                                    .pluck('disciplines.api_code')
                                                                    .uniq

      observation_diary_record = ObservationDiaryRecordNoteStudent.joins(observation_diary_record_note: [observation_diary_record: :discipline])
                                                                  .by_student_id(@student_id)
                                                                  .where("observation_diary_records.date < '#{@date}'")
                                                                  .pluck('disciplines.api_code')
                                                                  .uniq
      
      retorno = []
      retorno << build_hash(I18n.t('activerecord.models.daily_note.one'), daily_note) if daily_note.present?
      retorno << build_hash(I18n.t('activerecord.models.conceptual_exam.one'), conceptual_exam) if conceptual_exam.present?
      retorno << build_hash(I18n.t('activerecord.models.descriptive_exam.one'), descriptive_exam) if descriptive_exam.present?
      retorno << build_hash(I18n.t('activerecord.models.avaliation_exemption.one'), avaliation_exemption) if avaliation_exemption.present?
      retorno << build_hash(I18n.t('activerecord.models.transfer_note.one'), transfer_note) if transfer_note.present?
      retorno << build_hash(I18n.t('activerecord.models.complementary_exam.one'), complementary_exam) if complementary_exam.present?
      retorno << build_hash(I18n.t('activerecord.models.recovery_diary_record_student.one'), avaliation_recovery_diary_record) if avaliation_recovery_diary_record.present?
      retorno << build_hash(I18n.t('activerecord.models.school_term_recovery_diary_record.one'), school_term_recovery_diary_record) if school_term_recovery_diary_record.present?
      retorno << build_hash(I18n.t('activerecord.models.observation_diary_record.one'), observation_diary_record) if observation_diary_record.present?
      
      retorno
    end

    def build_hash(type, disciplines)
      {
        'type': type,
        'disciplines': disciplines
      }
    end
  end
end
