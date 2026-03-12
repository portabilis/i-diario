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
        without_auditing do
          DESTROY_STEPS.each { |step| unity_total += send(step) }
        end
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

    def without_auditing
      Audited.auditing_enabled = false
      yield
    ensure
      Audited.auditing_enabled = true
    end

    def extract_attributes(scope)
      scope.to_a.map(&:attributes)
    end

    def extract_avaliations_grades_attributes(avaliation_ids)
      return [] if avaliation_ids.empty?

      ActiveRecord::Base.connection.select_all(
        "SELECT * FROM avaliations_grades WHERE avaliation_id IN (#{avaliation_ids.join(',')})"
      ).to_a
    end

    SNAPSHOT_CHUNK_SIZE = 5_000

    def register_deleted_records(record_type, records_data)
      return if records_data.empty?

      records_data.each_slice(SNAPSHOT_CHUNK_SIZE) do |chunk|
        @deletion.discipline_record_deletion_postings.create!(
          record_type: record_type,
          records_data: chunk
        )
      end
    end

    def destroy_avaliations_and_children
      avaliations = @query.avaliations.to_a
      return 0 if avaliations.empty?

      avaliation_ids = avaliations.map(&:id)

      daily_notes = DailyNote.where(avaliation_id: avaliation_ids).to_a
      daily_note_ids = daily_notes.map(&:id)

      avaliation_recovery_diary_records_data = extract_attributes(
        AvaliationRecoveryDiaryRecord.where(avaliation_id: avaliation_ids)
      )
      daily_notes_data = daily_notes.map(&:attributes)
      daily_note_students_data = extract_attributes(
        DailyNoteStudent.with_discarded.where(daily_note_id: daily_note_ids)
      )
      avaliation_exemptions_data = extract_attributes(
        AvaliationExemption.with_discarded.where(avaliation_id: avaliation_ids)
      )
      avaliations_grades_data = extract_avaliations_grades_attributes(avaliation_ids)
      avaliations_data = avaliations.map(&:attributes)

      AvaliationRecoveryDiaryRecord.where(avaliation_id: avaliation_ids).delete_all
      DailyNoteStudent.with_discarded.where(daily_note_id: daily_note_ids).delete_all
      DailyNote.where(id: daily_note_ids).delete_all
      AvaliationExemption.with_discarded.where(avaliation_id: avaliation_ids).delete_all
      delete_join_table('avaliations_grades', 'avaliation_id', avaliation_ids)
      Avaliation.where(id: avaliation_ids).delete_all

      register_deleted_records('AvaliationRecoveryDiaryRecord', avaliation_recovery_diary_records_data)
      register_deleted_records('DailyNote', daily_notes_data)
      register_deleted_records('DailyNoteStudent', daily_note_students_data)
      register_deleted_records('AvaliationExemption', avaliation_exemptions_data)
      register_deleted_records('AvaliationsGrade', avaliations_grades_data)
      register_deleted_records('Avaliation', avaliations_data)

      avaliation_ids.size
    end

    def destroy_conceptual_exams_and_children
      conceptual_exam_ids = @query.conceptual_exams.pluck(:id)
      return 0 if conceptual_exam_ids.empty?

      values_scope = ConceptualExamValue.where(conceptual_exam_id: conceptual_exam_ids)
      values_scope = values_scope.where(discipline_id: @query.discipline_ids) if @query.discipline_ids.present?
      conceptual_exam_values_data = extract_attributes(values_scope)

      values_scope.delete_all

      exams_with_values = ConceptualExamValue.where(conceptual_exam_id: conceptual_exam_ids)
                                             .distinct
                                             .pluck(:conceptual_exam_id)
      orphan_ids = conceptual_exam_ids - exams_with_values
      conceptual_exams_data = extract_attributes(ConceptualExam.with_discarded.where(id: orphan_ids))

      ConceptualExam.with_discarded.where(id: orphan_ids).delete_all

      register_deleted_records('ConceptualExamValue', conceptual_exam_values_data)
      register_deleted_records('ConceptualExam', conceptual_exams_data)

      conceptual_exam_ids.size
    end

    def destroy_recovery_diary_records_and_children
      recovery_diary_record_ids = @query.recovery_diary_records.pluck(:id)
      return 0 if recovery_diary_record_ids.empty?

      recovery_diary_record_students_data = extract_attributes(
        RecoveryDiaryRecordStudent.with_discarded.where(recovery_diary_record_id: recovery_diary_record_ids)
      )
      school_term_recovery_diary_records_data = extract_attributes(
        SchoolTermRecoveryDiaryRecord.where(recovery_diary_record_id: recovery_diary_record_ids)
      )
      final_recovery_diary_records_data = extract_attributes(
        FinalRecoveryDiaryRecord.where(recovery_diary_record_id: recovery_diary_record_ids)
      )
      avaliation_recovery_diary_records_data = extract_attributes(
        AvaliationRecoveryDiaryRecord.where(recovery_diary_record_id: recovery_diary_record_ids)
      )
      avaliation_recovery_lowest_notes_data = extract_attributes(
        AvaliationRecoveryLowestNote.where(recovery_diary_record_id: recovery_diary_record_ids)
      )
      recovery_diary_records_data = @query.recovery_diary_records.to_a.map(&:attributes)

      RecoveryDiaryRecordStudent.with_discarded.where(recovery_diary_record_id: recovery_diary_record_ids).delete_all
      SchoolTermRecoveryDiaryRecord.where(recovery_diary_record_id: recovery_diary_record_ids).delete_all
      FinalRecoveryDiaryRecord.where(recovery_diary_record_id: recovery_diary_record_ids).delete_all
      AvaliationRecoveryDiaryRecord.where(recovery_diary_record_id: recovery_diary_record_ids).delete_all
      AvaliationRecoveryLowestNote.where(recovery_diary_record_id: recovery_diary_record_ids).delete_all
      RecoveryDiaryRecord.where(id: recovery_diary_record_ids).delete_all

      register_deleted_records('RecoveryDiaryRecordStudent', recovery_diary_record_students_data)
      register_deleted_records('SchoolTermRecoveryDiaryRecord', school_term_recovery_diary_records_data)
      register_deleted_records('FinalRecoveryDiaryRecord', final_recovery_diary_records_data)
      register_deleted_records('AvaliationRecoveryDiaryRecord', avaliation_recovery_diary_records_data)
      register_deleted_records('AvaliationRecoveryLowestNote', avaliation_recovery_lowest_notes_data)
      register_deleted_records('RecoveryDiaryRecord', recovery_diary_records_data)

      recovery_diary_record_ids.size
    end

    def destroy_daily_frequencies_and_children
      daily_frequencies = @query.daily_frequencies.to_a
      return 0 if daily_frequencies.empty?

      daily_frequency_ids = daily_frequencies.map(&:id)

      daily_frequency_students_data = extract_attributes(
        DailyFrequencyStudent.with_discarded.where(daily_frequency_id: daily_frequency_ids)
      )
      daily_frequencies_data = daily_frequencies.map(&:attributes)

      DailyFrequencyStudent.with_discarded.where(daily_frequency_id: daily_frequency_ids).delete_all
      DailyFrequency.where(id: daily_frequency_ids).delete_all

      register_deleted_records('DailyFrequencyStudent', daily_frequency_students_data)
      register_deleted_records('DailyFrequency', daily_frequencies_data)

      daily_frequency_ids.size
    end

    def destroy_discipline_content_records
      discipline_records = @query.discipline_content_records.to_a
      return 0 if discipline_records.empty?

      content_record_ids = discipline_records.map(&:content_record_id).compact.uniq

      discipline_content_records_data = discipline_records.map(&:attributes)
      content_records_data = extract_attributes(ContentRecord.where(id: content_record_ids))
      content_records_contents_data = extract_attributes(ContentRecordsContent.where(content_record_id: content_record_ids))

      ContentRecordsContent.where(content_record_id: content_record_ids).delete_all
      @query.discipline_content_records.delete_all
      ContentRecord.where(id: content_record_ids).delete_all

      register_deleted_records('DisciplineContentRecord', discipline_content_records_data)
      register_deleted_records('ContentRecord', content_records_data)
      register_deleted_records('ContentRecordsContent', content_records_contents_data)

      discipline_records.size
    end

    def destroy_discipline_lesson_plans
      discipline_plans = @query.discipline_lesson_plans.to_a
      return 0 if discipline_plans.empty?

      lesson_plan_ids = discipline_plans.map(&:lesson_plan_id).compact.uniq

      discipline_lesson_plans_data = discipline_plans.map(&:attributes)
      lesson_plans_data = extract_attributes(LessonPlan.where(id: lesson_plan_ids))
      contents_lesson_plans_data = extract_attributes(ContentsLessonPlan.where(lesson_plan_id: lesson_plan_ids))
      objectives_lesson_plans_data = extract_attributes(ObjectivesLessonPlan.where(lesson_plan_id: lesson_plan_ids))
      lesson_plan_attachments_data = extract_attributes(LessonPlanAttachment.where(lesson_plan_id: lesson_plan_ids))

      ContentsLessonPlan.where(lesson_plan_id: lesson_plan_ids).delete_all
      ObjectivesLessonPlan.where(lesson_plan_id: lesson_plan_ids).delete_all
      LessonPlanAttachment.where(lesson_plan_id: lesson_plan_ids).delete_all
      @query.discipline_lesson_plans.delete_all
      LessonPlan.where(id: lesson_plan_ids).delete_all

      register_deleted_records('DisciplineLessonPlan', discipline_lesson_plans_data)
      register_deleted_records('LessonPlan', lesson_plans_data)
      register_deleted_records('ContentsLessonPlan', contents_lesson_plans_data)
      register_deleted_records('ObjectivesLessonPlan', objectives_lesson_plans_data)
      register_deleted_records('LessonPlanAttachment', lesson_plan_attachments_data)

      discipline_plans.size
    end

    def destroy_discipline_teaching_plans
      discipline_plans = @query.discipline_teaching_plans.to_a
      return 0 if discipline_plans.empty?

      teaching_plan_ids = discipline_plans.map(&:teaching_plan_id).compact.uniq

      discipline_teaching_plans_data = discipline_plans.map(&:attributes)
      teaching_plans_data = extract_attributes(TeachingPlan.where(id: teaching_plan_ids))
      contents_teaching_plans_data = extract_attributes(ContentsTeachingPlan.where(teaching_plan_id: teaching_plan_ids))
      objectives_teaching_plans_data = extract_attributes(ObjectivesTeachingPlan.where(teaching_plan_id: teaching_plan_ids))
      teaching_plan_attachments_data = extract_attributes(TeachingPlanAttachment.where(teaching_plan_id: teaching_plan_ids))

      ContentsTeachingPlan.where(teaching_plan_id: teaching_plan_ids).delete_all
      ObjectivesTeachingPlan.where(teaching_plan_id: teaching_plan_ids).delete_all
      TeachingPlanAttachment.where(teaching_plan_id: teaching_plan_ids).delete_all
      @query.discipline_teaching_plans.delete_all
      TeachingPlan.where(id: teaching_plan_ids).delete_all

      register_deleted_records('DisciplineTeachingPlan', discipline_teaching_plans_data)
      register_deleted_records('TeachingPlan', teaching_plans_data)
      register_deleted_records('ContentsTeachingPlan', contents_teaching_plans_data)
      register_deleted_records('ObjectivesTeachingPlan', objectives_teaching_plans_data)
      register_deleted_records('TeachingPlanAttachment', teaching_plan_attachments_data)

      discipline_plans.size
    end

    def destroy_observation_diary_records_and_children
      observation_diary_record_ids = @query.observation_diary_records.pluck(:id)
      return 0 if observation_diary_record_ids.empty?

      note_ids = ObservationDiaryRecordNote.with_discarded
                                           .where(observation_diary_record_id: observation_diary_record_ids).pluck(:id)

      observation_diary_record_note_students_data = extract_attributes(
        ObservationDiaryRecordNoteStudent.with_discarded.where(observation_diary_record_note_id: note_ids)
      )
      observation_diary_record_notes_data = extract_attributes(
        ObservationDiaryRecordNote.with_discarded.where(observation_diary_record_id: observation_diary_record_ids)
      )
      observation_diary_record_attachments_data = extract_attributes(
        ObservationDiaryRecordAttachment.where(observation_diary_record_id: observation_diary_record_ids)
      )
      observation_diary_records_data = @query.observation_diary_records.to_a.map(&:attributes)

      ObservationDiaryRecordNoteStudent.with_discarded.where(observation_diary_record_note_id: note_ids).delete_all
      ObservationDiaryRecordNote.with_discarded.where(observation_diary_record_id: observation_diary_record_ids).delete_all
      ObservationDiaryRecordAttachment.where(observation_diary_record_id: observation_diary_record_ids).delete_all
      ObservationDiaryRecord.where(id: observation_diary_record_ids).delete_all

      register_deleted_records('ObservationDiaryRecordNoteStudent', observation_diary_record_note_students_data)
      register_deleted_records('ObservationDiaryRecordNote', observation_diary_record_notes_data)
      register_deleted_records('ObservationDiaryRecordAttachment', observation_diary_record_attachments_data)
      register_deleted_records('ObservationDiaryRecord', observation_diary_records_data)

      observation_diary_record_ids.size
    end

    def destroy_complementary_exams_and_children
      complementary_exams = @query.complementary_exams.to_a
      return 0 if complementary_exams.empty?

      complementary_exam_ids = complementary_exams.map(&:id)

      complementary_exam_students_data = extract_attributes(
        ComplementaryExamStudent.with_discarded.where(complementary_exam_id: complementary_exam_ids)
      )
      complementary_exams_data = complementary_exams.map(&:attributes)

      ComplementaryExamStudent.with_discarded.where(complementary_exam_id: complementary_exam_ids).delete_all
      ComplementaryExam.where(id: complementary_exam_ids).delete_all

      register_deleted_records('ComplementaryExamStudent', complementary_exam_students_data)
      register_deleted_records('ComplementaryExam', complementary_exams_data)

      complementary_exam_ids.size
    end

    def destroy_descriptive_exams_and_children
      descriptive_exams = @query.descriptive_exams.to_a
      return 0 if descriptive_exams.empty?

      descriptive_exam_ids = descriptive_exams.map(&:id)

      descriptive_exam_students_data = extract_attributes(
        DescriptiveExamStudent.with_discarded.where(descriptive_exam_id: descriptive_exam_ids)
      )
      descriptive_exams_data = descriptive_exams.map(&:attributes)

      DescriptiveExamStudent.with_discarded.where(descriptive_exam_id: descriptive_exam_ids).delete_all
      DescriptiveExam.where(id: descriptive_exam_ids).delete_all

      register_deleted_records('DescriptiveExamStudent', descriptive_exam_students_data)
      register_deleted_records('DescriptiveExam', descriptive_exams_data)

      descriptive_exam_ids.size
    end

    # TransferNote mantém destroy! pois tem before_destroy com lógica custom
    # (TransferNotes.new(self).destroy)
    def destroy_transfer_notes
      transfer_notes = @query.transfer_notes.to_a
      return 0 if transfer_notes.empty?

      transfer_note_ids = transfer_notes.map(&:id)

      transfer_note_daily_note_students_data = extract_attributes(
        DailyNoteStudent.with_discarded.where(transfer_note_id: transfer_note_ids)
      )
      transfer_notes_data = transfer_notes.map(&:attributes)

      transfer_notes.each do |record|
        record.step_id = record.step.try(:id)
        record.destroy!
      end

      register_deleted_records('TransferNoteDailyNoteStudent', transfer_note_daily_note_students_data)
      register_deleted_records('TransferNote', transfer_notes_data)
      transfer_notes.size
    end

    def delete_join_table(table_name, column_name, ids)
      return if ids.empty?

      ActiveRecord::Base.connection.execute(
        "DELETE FROM #{table_name} WHERE #{column_name} IN (#{ids.join(',')})"
      )
    end
  end
end
