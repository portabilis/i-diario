# frozen_string_literal: true

module Api
  # Destroys discipline records in correct FK order within a transaction.
  # Usa delete_all ao invés de destroy! para performance, pois o audit trail
  # já é garantido pelo snapshot em discipline_record_deletion_postings.
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

    BATCH_SIZE = 5_000

    def initialize(unities:, courses:, grades:, disciplines:, year:, user:, deletion: nil)
      @filters = {
        unities: unities, courses: courses, grades: grades,
        disciplines: disciplines, year: year
      }
      @user = user.to_s
      @deletion = deletion
    end

    def call
      total = 0

      @deletion ||= create_discipline_record_deletion

      Array(@filters[:unities]).each do |unity_code|
        count = process_unity(unity_code)
        next if count.zero?

        total += count
        @deletion.update!(total_deleted: total)

        Rails.logger.info(
          "[DisciplineRecordsDestroyer] unity=#{unity_code} deleted=#{count} total=#{total}"
        )
      end

      total
    end

    private

    def process_unity(unity_code)
      unity_total = 0
      @query = DisciplineRecordsQuery.new(**@filters.merge(unities: [unity_code]))

      ActiveRecord::Base.transaction do
        DESTROY_STEPS.each { |step| unity_total += send(step) }
      end

      unity_total
    end

    def create_discipline_record_deletion
      DisciplineRecordDeletion.create!(
        filters: {
          year: @filters[:year].to_i,
          unities_api_code: @filters[:unities],
          courses_api_code: @filters[:courses],
          grades_api_code: @filters[:grades],
          disciplines_api_code: @filters[:disciplines],
          user_api_code: @user
        }
      )
    end

    def snapshot_records(record_type, scope)
      scope.find_in_batches(batch_size: BATCH_SIZE) do |batch|
        @deletion.discipline_record_deletion_postings.create!(
          record_type: record_type,
          records_data: batch.map(&:attributes)
        )
      end
    end

    def destroy_avaliations_and_children
      avaliation_ids = @query.avaliations.pluck(:id)
      return 0 if avaliation_ids.empty?

      daily_note_ids = DailyNote.where(avaliation_id: avaliation_ids).pluck(:id)

      snapshot_records('AvaliationRecoveryDiaryRecord',
                       AvaliationRecoveryDiaryRecord.where(avaliation_id: avaliation_ids))
      snapshot_records('DailyNoteStudent', DailyNoteStudent.with_discarded.where(daily_note_id: daily_note_ids))
      snapshot_records('DailyNote', DailyNote.where(avaliation_id: avaliation_ids))
      snapshot_records('AvaliationExemption', AvaliationExemption.with_discarded.where(avaliation_id: avaliation_ids))
      snapshot_avaliations_grades(avaliation_ids)
      snapshot_records('Avaliation', Avaliation.where(id: avaliation_ids))

      AvaliationRecoveryDiaryRecord.where(avaliation_id: avaliation_ids).delete_all
      DailyNoteStudent.with_discarded.where(daily_note_id: daily_note_ids).delete_all
      DailyNote.where(id: daily_note_ids).delete_all
      AvaliationExemption.with_discarded.where(avaliation_id: avaliation_ids).delete_all
      delete_join_table('avaliations_grades', 'avaliation_id', avaliation_ids)
      Avaliation.where(id: avaliation_ids).delete_all

      avaliation_ids.size
    end

    def destroy_conceptual_exams_and_children
      conceptual_exam_ids = @query.conceptual_exams.pluck(:id)
      return 0 if conceptual_exam_ids.empty?

      values_scope = ConceptualExamValue.where(conceptual_exam_id: conceptual_exam_ids)
      values_scope = values_scope.where(discipline_id: @query.discipline_ids) if @query.discipline_ids.present?

      snapshot_records('ConceptualExamValue', values_scope)
      values_scope.delete_all

      exams_with_values = ConceptualExamValue.where(conceptual_exam_id: conceptual_exam_ids)
                                             .distinct
                                             .pluck(:conceptual_exam_id)
      orphan_ids = conceptual_exam_ids - exams_with_values

      snapshot_records('ConceptualExam', ConceptualExam.with_discarded.where(id: orphan_ids))
      ConceptualExam.with_discarded.where(id: orphan_ids).delete_all

      conceptual_exam_ids.size
    end

    def destroy_recovery_diary_records_and_children
      recovery_diary_record_ids = @query.recovery_diary_records.pluck(:id)
      return 0 if recovery_diary_record_ids.empty?

      snapshot_records('RecoveryDiaryRecordStudent',
                       RecoveryDiaryRecordStudent.with_discarded.where(recovery_diary_record_id: recovery_diary_record_ids))
      snapshot_records('SchoolTermRecoveryDiaryRecord',
                       SchoolTermRecoveryDiaryRecord.where(recovery_diary_record_id: recovery_diary_record_ids))
      snapshot_records('FinalRecoveryDiaryRecord',
                       FinalRecoveryDiaryRecord.where(recovery_diary_record_id: recovery_diary_record_ids))
      snapshot_records('AvaliationRecoveryDiaryRecord',
                       AvaliationRecoveryDiaryRecord.where(recovery_diary_record_id: recovery_diary_record_ids))
      snapshot_records('AvaliationRecoveryLowestNote',
                       AvaliationRecoveryLowestNote.where(recovery_diary_record_id: recovery_diary_record_ids))
      snapshot_records('RecoveryDiaryRecord', RecoveryDiaryRecord.where(id: recovery_diary_record_ids))

      RecoveryDiaryRecordStudent.with_discarded.where(recovery_diary_record_id: recovery_diary_record_ids).delete_all
      SchoolTermRecoveryDiaryRecord.where(recovery_diary_record_id: recovery_diary_record_ids).delete_all
      FinalRecoveryDiaryRecord.where(recovery_diary_record_id: recovery_diary_record_ids).delete_all
      AvaliationRecoveryDiaryRecord.where(recovery_diary_record_id: recovery_diary_record_ids).delete_all
      AvaliationRecoveryLowestNote.where(recovery_diary_record_id: recovery_diary_record_ids).delete_all
      RecoveryDiaryRecord.where(id: recovery_diary_record_ids).delete_all

      recovery_diary_record_ids.size
    end

    def destroy_daily_frequencies_and_children
      daily_frequency_ids = @query.daily_frequencies.pluck(:id)
      return 0 if daily_frequency_ids.empty?

      snapshot_records('DailyFrequencyStudent', DailyFrequencyStudent.with_discarded.where(daily_frequency_id: daily_frequency_ids))
      snapshot_records('DailyFrequency', DailyFrequency.where(id: daily_frequency_ids))

      DailyFrequencyStudent.with_discarded.where(daily_frequency_id: daily_frequency_ids).delete_all
      DailyFrequency.where(id: daily_frequency_ids).delete_all

      daily_frequency_ids.size
    end

    def destroy_discipline_content_records
      scope = @query.discipline_content_records
      count = scope.count
      return 0 if count.zero?

      content_record_ids = scope.pluck(:content_record_id).compact.uniq

      snapshot_records('DisciplineContentRecord', scope)
      snapshot_records('ContentRecord', ContentRecord.where(id: content_record_ids))
      snapshot_records('ContentRecordsContent', ContentRecordsContent.where(content_record_id: content_record_ids))

      ContentRecordsContent.where(content_record_id: content_record_ids).delete_all
      scope.delete_all
      ContentRecord.where(id: content_record_ids).delete_all

      count
    end

    def destroy_discipline_lesson_plans
      scope = @query.discipline_lesson_plans
      count = scope.count
      return 0 if count.zero?

      lesson_plan_ids = scope.pluck(:lesson_plan_id).compact.uniq

      snapshot_records('DisciplineLessonPlan', scope)
      snapshot_records('LessonPlan', LessonPlan.where(id: lesson_plan_ids))
      snapshot_records('ContentsLessonPlan', ContentsLessonPlan.where(lesson_plan_id: lesson_plan_ids))
      snapshot_records('ObjectivesLessonPlan', ObjectivesLessonPlan.where(lesson_plan_id: lesson_plan_ids))
      snapshot_records('LessonPlanAttachment', LessonPlanAttachment.where(lesson_plan_id: lesson_plan_ids))

      ContentsLessonPlan.where(lesson_plan_id: lesson_plan_ids).delete_all
      ObjectivesLessonPlan.where(lesson_plan_id: lesson_plan_ids).delete_all
      LessonPlanAttachment.where(lesson_plan_id: lesson_plan_ids).delete_all
      scope.delete_all
      LessonPlan.where(id: lesson_plan_ids).delete_all

      count
    end

    def destroy_discipline_teaching_plans
      scope = @query.discipline_teaching_plans
      count = scope.count
      return 0 if count.zero?

      teaching_plan_ids = scope.pluck(:teaching_plan_id).compact.uniq

      snapshot_records('DisciplineTeachingPlan', scope)
      snapshot_records('TeachingPlan', TeachingPlan.where(id: teaching_plan_ids))
      snapshot_records('ContentsTeachingPlan', ContentsTeachingPlan.where(teaching_plan_id: teaching_plan_ids))
      snapshot_records('ObjectivesTeachingPlan', ObjectivesTeachingPlan.where(teaching_plan_id: teaching_plan_ids))
      snapshot_records('TeachingPlanAttachment', TeachingPlanAttachment.where(teaching_plan_id: teaching_plan_ids))

      ContentsTeachingPlan.where(teaching_plan_id: teaching_plan_ids).delete_all
      ObjectivesTeachingPlan.where(teaching_plan_id: teaching_plan_ids).delete_all
      TeachingPlanAttachment.where(teaching_plan_id: teaching_plan_ids).delete_all
      scope.delete_all
      TeachingPlan.where(id: teaching_plan_ids).delete_all

      count
    end

    def destroy_observation_diary_records_and_children
      observation_diary_record_ids = @query.observation_diary_records.pluck(:id)
      return 0 if observation_diary_record_ids.empty?

      note_ids = ObservationDiaryRecordNote.with_discarded
                                           .where(observation_diary_record_id: observation_diary_record_ids).pluck(:id)

      snapshot_records('ObservationDiaryRecordNoteStudent',
                       ObservationDiaryRecordNoteStudent.with_discarded.where(observation_diary_record_note_id: note_ids))
      snapshot_records('ObservationDiaryRecordNote',
                       ObservationDiaryRecordNote.with_discarded.where(observation_diary_record_id: observation_diary_record_ids))
      snapshot_records('ObservationDiaryRecordAttachment',
                       ObservationDiaryRecordAttachment.where(observation_diary_record_id: observation_diary_record_ids))
      snapshot_records('ObservationDiaryRecord', ObservationDiaryRecord.where(id: observation_diary_record_ids))

      ObservationDiaryRecordNoteStudent.with_discarded.where(observation_diary_record_note_id: note_ids).delete_all
      ObservationDiaryRecordNote.with_discarded
                               .where(observation_diary_record_id: observation_diary_record_ids).delete_all
      ObservationDiaryRecordAttachment.where(observation_diary_record_id: observation_diary_record_ids).delete_all
      ObservationDiaryRecord.where(id: observation_diary_record_ids).delete_all

      observation_diary_record_ids.size
    end

    def destroy_complementary_exams_and_children
      complementary_exam_ids = @query.complementary_exams.pluck(:id)
      return 0 if complementary_exam_ids.empty?

      snapshot_records('ComplementaryExamStudent',
                       ComplementaryExamStudent.with_discarded.where(complementary_exam_id: complementary_exam_ids))
      snapshot_records('ComplementaryExam', ComplementaryExam.where(id: complementary_exam_ids))

      ComplementaryExamStudent.with_discarded.where(complementary_exam_id: complementary_exam_ids).delete_all
      ComplementaryExam.where(id: complementary_exam_ids).delete_all

      complementary_exam_ids.size
    end

    def destroy_descriptive_exams_and_children
      descriptive_exam_ids = @query.descriptive_exams.pluck(:id)
      return 0 if descriptive_exam_ids.empty?

      snapshot_records('DescriptiveExamStudent',
                       DescriptiveExamStudent.with_discarded.where(descriptive_exam_id: descriptive_exam_ids))
      snapshot_records('DescriptiveExam', DescriptiveExam.where(id: descriptive_exam_ids))

      DescriptiveExamStudent.with_discarded.where(descriptive_exam_id: descriptive_exam_ids).delete_all
      DescriptiveExam.where(id: descriptive_exam_ids).delete_all

      descriptive_exam_ids.size
    end

    def destroy_transfer_notes
      transfer_note_ids = @query.transfer_notes.pluck(:id)
      return 0 if transfer_note_ids.empty?

      snapshot_records('TransferNoteDailyNoteStudent',
                       DailyNoteStudent.with_discarded.where(transfer_note_id: transfer_note_ids))
      snapshot_records('TransferNote', TransferNote.where(id: transfer_note_ids))

      # Replica o before_destroy do TransferNote: desvincula DailyNoteStudents
      DailyNoteStudent.where(transfer_note_id: transfer_note_ids).update_all(transfer_note_id: nil, note: nil)
      TransferNote.where(id: transfer_note_ids).delete_all

      transfer_note_ids.size
    end

    def snapshot_avaliations_grades(avaliation_ids)
      return if avaliation_ids.empty?

      avaliation_ids.each_slice(BATCH_SIZE) do |ids_chunk|
        data = ActiveRecord::Base.connection.select_all(
          "SELECT * FROM avaliations_grades WHERE avaliation_id IN (#{ids_chunk.join(',')})"
        ).to_a

        next if data.empty?

        @deletion.discipline_record_deletion_postings.create!(
          record_type: 'AvaliationsGrade',
          records_data: data
        )
      end
    end

    def delete_join_table(table_name, column_name, ids)
      return if ids.empty?

      ActiveRecord::Base.connection.execute(
        "DELETE FROM #{table_name} WHERE #{column_name} IN (#{ids.join(',')})"
      )
    end
  end
end
