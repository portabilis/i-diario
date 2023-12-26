class RemoveDuplicatedDisciplines < ActiveRecord::Migration[4.2]
  def change
    duplicated_api_codes = Discipline.all
                                     .group(:api_code)
                                     .select(:api_code)
                                     .having('count(api_code) > 1')
                                     .pluck(:api_code)

    return if duplicated_api_codes.blank?

    duplicated = Discipline.where(api_code: duplicated_api_codes)

    duplicated.group_by(&:api_code).each do |api_code, disciplines|
      selected = disciplines[0]
      to_delete = disciplines[1..-1]
      to_delete_ids = to_delete.map(&:id)

      ActiveRecord::Base.transaction do
        AbsenceJustification.where(discipline_id: to_delete_ids)
                            .update_all(discipline_id: selected.id)

        User.where(current_discipline_id: to_delete_ids)
            .update_all(current_discipline_id: selected.id)

        TransferNote.where(discipline_id: to_delete_ids)
                    .update_all(discipline_id: selected.id)

        TeacherDisciplineClassroom.where(discipline_id: to_delete_ids)
                                  .update_all(discipline_id: selected.id)

        StudentEnrollmentDependence.where(discipline_id: to_delete_ids)
                                   .update_all(discipline_id: selected.id)

        SchoolCalendarEvent.where(discipline_id: to_delete_ids)
                           .update_all(discipline_id: selected.id)

        RecoveryDiaryRecord.where(discipline_id: to_delete_ids)
                           .update_all(discipline_id: selected.id)

        ObservationDiaryRecord.where(discipline_id: to_delete_ids)
                              .update_all(discipline_id: selected.id)

        DisciplineTeachingPlan.where(discipline_id: to_delete_ids)
                              .update_all(discipline_id: selected.id)

        DisciplineLessonPlan.where(discipline_id: to_delete_ids)
                            .update_all(discipline_id: selected.id)

        DisciplineContentRecord.where(discipline_id: to_delete_ids)
                               .update_all(discipline_id: selected.id)

        DescriptiveExam.where(discipline_id: to_delete_ids)
                       .update_all(discipline_id: selected.id)

        DailyFrequency.where(discipline_id: to_delete_ids)
                      .update_all(discipline_id: selected.id)

        ConceptualExamValue.where(discipline_id: to_delete_ids)
                           .update_all(discipline_id: selected.id)

        Avaliation.where(discipline_id: to_delete_ids)
                  .update_all(discipline_id: selected.id)

        SpecificStep.where(discipline_id: to_delete_ids)
                    .update_all(discipline_id: selected.id)

        to_delete.each(&:delete)
      end
    end
  end
end
