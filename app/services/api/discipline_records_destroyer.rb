# frozen_string_literal: true

module Api
  # Destroys discipline records in correct FK order within a transaction
  class DisciplineRecordsDestroyer
    DESTROY_STEPS = %i[
      destroy_avaliations_and_children
      destroy_conceptual_exams_and_children
      destroy_recovery_diary_records_and_children
      destroy_daily_frequencies_and_children
      destroy_discipline_content_records
      destroy_discipline_lesson_plans
      destroy_discipline_teaching_plans
      destroy_observation_diary_records_and_children
      destroy_complementary_exams_and_children
      destroy_transfer_notes
    ].freeze

    def initialize(unities:, courses:, grades:, disciplines:, year:)
      @query = DisciplineRecordsQuery.new(
        unities: unities, courses: courses, grades: grades,
        disciplines: disciplines, year: year
      )
    end

    def call
      total = 0

      ActiveRecord::Base.transaction do
        DESTROY_STEPS.each { |step| total += send(step) }
      end

      total
    end

    private

    def destroy_avaliations_and_children
      avaliation_ids = @query.avaliations.pluck(:id)
      return 0 if avaliation_ids.empty?

      count = destroy_daily_notes_for(avaliation_ids)
      count += AvaliationExemption.where(avaliation_id: avaliation_ids).destroy_all.size
      count + Avaliation.where(id: avaliation_ids).destroy_all.size
    end

    def destroy_daily_notes_for(avaliation_ids)
      daily_note_ids = DailyNote.where(avaliation_id: avaliation_ids).pluck(:id)
      return 0 if daily_note_ids.empty?

      count = DailyNoteStudent.where(daily_note_id: daily_note_ids).destroy_all.size
      count + DailyNote.where(id: daily_note_ids).destroy_all.size
    end

    def destroy_conceptual_exams_and_children
      ids = @query.conceptual_exams.pluck(:id)
      return 0 if ids.empty?

      count = ConceptualExamValue.where(conceptual_exam_id: ids).destroy_all.size
      count + ConceptualExam.where(id: ids).destroy_all.size
    end

    def destroy_recovery_diary_records_and_children
      ids = @query.recovery_diary_records.pluck(:id)
      return 0 if ids.empty?

      count = destroy_recovery_children(ids)
      count + RecoveryDiaryRecord.where(id: ids).destroy_all.size
    end

    def destroy_recovery_children(ids)
      count = RecoveryDiaryRecordStudent.where(recovery_diary_record_id: ids).destroy_all.size
      count += SchoolTermRecoveryDiaryRecord.where(recovery_diary_record_id: ids).destroy_all.size
      count += FinalRecoveryDiaryRecord.where(recovery_diary_record_id: ids).destroy_all.size
      count + AvaliationRecoveryDiaryRecord.where(recovery_diary_record_id: ids).destroy_all.size
    end

    def destroy_daily_frequencies_and_children
      ids = @query.daily_frequencies.pluck(:id)
      return 0 if ids.empty?

      count = DailyFrequencyStudent.where(daily_frequency_id: ids).destroy_all.size
      count + DailyFrequency.where(id: ids).destroy_all.size
    end

    def destroy_discipline_content_records
      @query.discipline_content_records.destroy_all.size
    end

    def destroy_discipline_lesson_plans
      @query.discipline_lesson_plans.destroy_all.size
    end

    def destroy_discipline_teaching_plans
      @query.discipline_teaching_plans.destroy_all.size
    end

    def destroy_observation_diary_records_and_children
      ids = @query.observation_diary_records.pluck(:id)
      return 0 if ids.empty?

      count = ObservationDiaryRecordNote.where(observation_diary_record_id: ids).destroy_all.size
      count + ObservationDiaryRecord.where(id: ids).destroy_all.size
    end

    def destroy_complementary_exams_and_children
      ids = @query.complementary_exams.pluck(:id)
      return 0 if ids.empty?

      count = ComplementaryExamStudent.where(complementary_exam_id: ids).destroy_all.size
      count + ComplementaryExam.where(id: ids).destroy_all.size
    end

    def destroy_transfer_notes
      @query.transfer_notes.destroy_all.size
    end
  end
end
