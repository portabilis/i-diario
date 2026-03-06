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
      destroy_descriptive_exams_and_children
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

      force_destroy(AvaliationRecoveryDiaryRecord.where(avaliation_id: avaliation_ids))
      destroy_daily_notes_for(avaliation_ids)
      force_destroy(AvaliationExemption.with_discarded.where(avaliation_id: avaliation_ids))
      force_destroy(Avaliation.where(id: avaliation_ids))
      avaliation_ids.size
    end

    def destroy_daily_notes_for(avaliation_ids)
      daily_note_ids = DailyNote.where(avaliation_id: avaliation_ids).pluck(:id)
      return 0 if daily_note_ids.empty?

      force_destroy(DailyNoteStudent.where(daily_note_id: daily_note_ids))
      force_destroy(DailyNote.where(id: daily_note_ids))
    end

    def destroy_conceptual_exams_and_children
      conceptual_exam_ids = @query.conceptual_exams.pluck(:id)
      return 0 if conceptual_exam_ids.empty?

      values_scope = ConceptualExamValue.where(conceptual_exam_id: conceptual_exam_ids)
      values_scope = values_scope.where(discipline_id: @query.discipline_ids) if @query.discipline_ids.present?
      force_destroy(values_scope)

      exams_with_values = ConceptualExamValue.where(conceptual_exam_id: conceptual_exam_ids)
                                             .distinct
                                             .pluck(:conceptual_exam_id)
      orphan_ids = conceptual_exam_ids - exams_with_values
      force_destroy(ConceptualExam.with_discarded.where(id: orphan_ids))
      conceptual_exam_ids.size
    end

    def destroy_recovery_diary_records_and_children
      recovery_diary_record_ids = @query.recovery_diary_records.pluck(:id)
      return 0 if recovery_diary_record_ids.empty?

      destroy_recovery_children(recovery_diary_record_ids)
      force_destroy(RecoveryDiaryRecord.where(id: recovery_diary_record_ids))
      recovery_diary_record_ids.size
    end

    def destroy_recovery_children(recovery_diary_record_ids)
      force_destroy(RecoveryDiaryRecordStudent.where(recovery_diary_record_id: recovery_diary_record_ids))
      force_destroy(SchoolTermRecoveryDiaryRecord.where(recovery_diary_record_id: recovery_diary_record_ids))
      force_destroy(FinalRecoveryDiaryRecord.where(recovery_diary_record_id: recovery_diary_record_ids))
      force_destroy(AvaliationRecoveryDiaryRecord.where(recovery_diary_record_id: recovery_diary_record_ids))
    end

    def destroy_daily_frequencies_and_children
      daily_frequency_ids = @query.daily_frequencies.pluck(:id)
      return 0 if daily_frequency_ids.empty?

      # DailyFrequencyStudent é auto-deletado via before_destroy do DailyFrequency
      force_destroy(DailyFrequency.where(id: daily_frequency_ids))
    end

    def destroy_discipline_content_records
      force_destroy(@query.discipline_content_records)
    end

    def destroy_discipline_lesson_plans
      force_destroy(@query.discipline_lesson_plans)
    end

    def destroy_discipline_teaching_plans
      force_destroy(@query.discipline_teaching_plans)
    end

    def destroy_observation_diary_records_and_children
      observation_diary_record_ids = @query.observation_diary_records.pluck(:id)
      return 0 if observation_diary_record_ids.empty?

      force_destroy(ObservationDiaryRecordNote.where(observation_diary_record_id: observation_diary_record_ids))
      force_destroy(ObservationDiaryRecord.where(id: observation_diary_record_ids))
      observation_diary_record_ids.size
    end

    def destroy_complementary_exams_and_children
      complementary_exam_ids = @query.complementary_exams.pluck(:id)
      return 0 if complementary_exam_ids.empty?

      force_destroy(ComplementaryExamStudent.where(complementary_exam_id: complementary_exam_ids))
      force_destroy(ComplementaryExam.where(id: complementary_exam_ids))
      complementary_exam_ids.size
    end

    def destroy_descriptive_exams_and_children
      descriptive_exam_ids = @query.descriptive_exams.pluck(:id)
      return 0 if descriptive_exam_ids.empty?

      force_destroy(DescriptiveExamStudent.where(descriptive_exam_id: descriptive_exam_ids))
      force_destroy(DescriptiveExam.where(id: descriptive_exam_ids))
      descriptive_exam_ids.size
    end

    def destroy_transfer_notes
      count = 0

      @query.transfer_notes.each do |record|
        record.step_id = record.step.try(:id)
        record.destroy!
        count += 1
      end

      count
    end

    def force_destroy(scope)
      records = scope.to_a
      records.each(&:destroy!)
      records.size
    end
  end
end
