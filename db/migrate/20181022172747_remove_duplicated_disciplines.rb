class RemoveDuplicatedDisciplines < ActiveRecord::Migration
  def change
    duplicated_api_codes = Discipline.all.
      group(:api_code).
      select(:api_code).
      having('count(api_code) > 1').pluck(:api_code)

    return if duplicated_api_codes.blank?

    duplicated = Discipline.where(api_code: duplicated_api_codes)
    duplicated.group_by(&:api_code).each do |api_code, disciplines|
      selected = disciplines[0]
      to_delete = disciplines[1..-1]
      to_delete_ids = to_delete.map(&:id)

      ActiveRecord::Base.transaction do
        puts AbsenceJustification.where(discipline_id: to_delete_ids).
          update_all(discipline_id: selected.id)
        puts User.where(current_discipline_id: to_delete_ids).
          update_all(current_discipline_id: selected.id)
        puts TransferNote.where(discipline_id: to_delete_ids).
          update_all(discipline_id: selected.id)
        puts TeacherDisciplineClassroom.where(discipline_id: to_delete_ids).
          update_all(discipline_id: selected.id)
        puts StudentEnrollmentDependence.where(discipline_id: to_delete_ids).
          update_all(discipline_id: selected.id)
        puts SchoolCalendarEvent.where(discipline_id: to_delete_ids).
          update_all(discipline_id: selected.id)
        puts RecoveryDiaryRecord.where(discipline_id: to_delete_ids).
          update_all(discipline_id: selected.id)
        puts ObservationDiaryRecord.where(discipline_id: to_delete_ids).
          update_all(discipline_id: selected.id)
        puts DisciplineTeachingPlan.where(discipline_id: to_delete_ids).
          update_all(discipline_id: selected.id)
        puts DisciplineLessonPlan.where(discipline_id: to_delete_ids).
          update_all(discipline_id: selected.id)
        puts DisciplineContentRecord.where(discipline_id: to_delete_ids).
          update_all(discipline_id: selected.id)
        puts DescriptiveExam.where(discipline_id: to_delete_ids).
          update_all(discipline_id: selected.id)
        puts DailyFrequency.where(discipline_id: to_delete_ids).
          update_all(discipline_id: selected.id)
        puts ConceptualExamValue.where(discipline_id: to_delete_ids).
          update_all(discipline_id: selected.id)
        puts Avaliation.where(discipline_id: to_delete_ids).
          update_all(discipline_id: selected.id)

        to_delete.each(&:delete)
      end
    end
  end
end
