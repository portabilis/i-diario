module Api
  class StudentActivityAfterDate
    def student_activities(student_id, date)
      activities_query(student_id, date)

      retorno = []

      retorno << build_hash(I18n.t('activerecord.models.daily_note.one'), @daily_note.presence)

      if @conceptual_exam.present?
        retorno << build_hash(I18n.t('activerecord.models.conceptual_exam.one'), @conceptual_exam)
      end
      if @descriptive_exam.present?
        retorno << build_hash(I18n.t('activerecord.models.descriptive_exam.one'), @descriptive_exam)
      end
      if @avaliation_exemption.present?
        retorno << build_hash(I18n.t('activerecord.models.avaliation_exemption.one'), @avaliation_exemption)
      end
      if @transfer_note.present?
        retorno << build_hash(I18n.t('activerecord.models.transfer_note.one'), @transfer_note)
      end
      if @complementary_exam.present?
        retorno << build_hash(I18n.t('activerecord.models.complementary_exam.one'), @complementary_exam)
      end
      if @avaliation_recovery_diary_record.present?
        retorno << build_hash(I18n.t('activerecord.models.recovery_diary_record_student.one'),
                              @avaliation_recovery_diary_record)
      end
      if @school_term_recovery_diary_record.present?
        retorno << build_hash(I18n.t('activerecord.models.school_term_recovery_diary_record.one'),
                              @school_term_recovery_diary_record)
      end
      if @observation_diary_record.present?
        retorno << build_hash(I18n.t('activerecord.models.observation_diary_record.one'),
                              @observation_diary_record)
      end

      if @general_descriptive_exam
        retorno << build_hash(I18n.t('activerecord.models.descriptive_exam.one'), @general_descriptive_exam)
      end

      retorno
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
