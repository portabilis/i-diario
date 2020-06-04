module Api
  class DisciplineClassroomActivity
    def initialize(discipline_id, classrooms_ids)
      @discipline_id = discipline_id
      @classrooms_ids = classrooms_ids
    end

    def any_activity?
      return true if DailyFrequency.where(classroom_id: @classrooms_ids, discipline_id: @discipline_id).exists?

      return true if Avaliation.where(classroom_id: @classrooms_ids, discipline_id: @discipline_id).exists?

      return true if ConceptualExamValue.joins(:conceptual_exam)
                                        .where(conceptual_exams: { classroom_id: @classrooms_ids })
                                        .where(discipline_id: @discipline_id)
                                        .exists?

      return true if DescriptiveExam.where(classroom_id: @classrooms_ids, discipline_id: @discipline_id).exists?

      return true if DisciplineContentRecord.joins(:content_record)
                                            .where(content_records: { classroom_id: @classrooms_ids })
                                            .where(discipline_id: @discipline_id)
                                            .exists?

      return true if DisciplineLessonPlan.joins(:lesson_plan)
                                         .where(lesson_plans: { classroom_id: @classrooms_ids })
                                         .where(discipline_id: @discipline_id)
                                         .exists?

      return true if RecoveryDiaryRecord.where(classroom_id: @classrooms_ids, discipline_id: @discipline_id)
                                        .exists?

      return true if ComplementaryExam.where(classroom_id: @classrooms_ids, discipline_id: @discipline_id)
                                      .exists?

      return true if AbsenceJustificationsDiscipline.joins(:absence_justification)
                                                    .where(absence_justifications: {
                                                             classroom_id: @classrooms_ids
                                                           })
                                                    .where(discipline_id: @discipline_id)
                                                    .exists?

      return true if ObservationDiaryRecord.where(classroom_id: @classrooms_ids, discipline_id: @discipline_id)
                                           .exists?

      return true if TransferNote.where(classroom_id: @classrooms_ids, discipline_id: @discipline_id).exists?

      false
    end
  end
end
