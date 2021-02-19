module Api
  class ActivityAfterDepartureDate
    def initialize(student_id, departure_date)
      @student_id = student_id
      @departure_date = departure_date
    end

    def has_activities
      one_query = DailyNoteStudent.joins(daily_note: [avaliation: :discipline]).by_student_id(@student_id).where("avaliations.test_date < '#{@departure_date}'").pluck('disciplines.api_code').uniq
      two_query = ConceptualExam.joins(conceptual_exam_values: :discipline).by_student_id(@student_id).where("recorded_at < '#{@departure_date}'").pluck('disciplines.api_code').uniq
      three_query = DescriptiveExamStudent.joins(descriptive_exam: :discipline).by_student_id(@student_id).where("descriptive_exams.recorded_at < '#{@departure_date}'").pluck('disciplines.api_code').uniq
      four_query = DescriptiveExamStudent.joins(:descriptive_exam).by_student_id(@student_id).where("descriptive_exams.recorded_at < '#{@departure_date}'").where(descriptive_exams: {discipline_id: nil})
      five_query = AvaliationExemption.joins(avaliation: :discipline).by_student(@student_id).where("avaliations.test_date < '#{@departure_date}'").pluck('disciplines.api_code').uniq
      six_query = TransferNote.joins(:student, :discipline).where(student_id: @student_id).where("transfer_notes.recorded_at < '#{@departure_date}'").pluck('disciplines.api_code').uniq
      seven_query = ComplementaryExamStudent.joins(complementary_exam: :discipline).by_student_id(@student_id).where("complementary_exams.recorded_at < '#{@departure_date}'").pluck('disciplines.api_code').uniq
      # eigth_query = ComplementaryExamStudent.joins(complementary_exam: :discipline).by_student_id(@student_id).where("complementary_exams.recorded_at < '#{@departure_date}'").pluck('disciplines.api_code').uniq
      # nine_query = ComplementaryExamStudent.joins(complementary_exam: :discipline).by_student_id(@student_id).where("complementary_exams.recorded_at < '#{@departure_date}'").pluck('disciplines.api_code').uniq
      ten_query = ObservationDiaryRecordNoteStudent.joins(observation_diary_record_note: [observation_diary_record: :discipline]).by_student_id(@student_id).where("observation_diary_records.date < '#{@departure_date}'").pluck('disciplines.api_code').uniq
      
      retorno = {}
      retorno[I18n.t('activerecord.models.daily_note.one')] = one_query if one_query.present?
      retorno[I18n.t('activerecord.models.conceptual_exam.one')] = two_query if two_query.present?
      retorno[I18n.t('activerecord.models.descriptive_exam.one')] = three_query if three_query.present?
      retorno[I18n.t('activerecord.models.descriptive_exam.one')] = 'Geral' if four_query.present?
      retorno[I18n.t('activerecord.models.avaliation_exemption.one')] = five_query if five_query.present?
      retorno[I18n.t('activerecord.models.transfer_note.one')] = six_query if six_query.present?
      retorno[I18n.t('activerecord.models.complementary_exam.one')] = seven_query if seven_query.present?
      # retorno[I18n.t('activerecord.models.complementary_exam.one')] = eigth_query if eigth_query.present?
      # retorno[I18n.t('activerecord.models.complementary_exam.one')] = nine_query if nine_query.present?
      retorno[I18n.t('activerecord.models.observation_diary_record.one')] = ten_query if ten_query.present?

      retorno
    end
  end
end
