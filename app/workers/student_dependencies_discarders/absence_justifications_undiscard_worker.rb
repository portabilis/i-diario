class AbsenceJustificationsUndiscardWorker < BaseStudentDependenciesDiscarderWorker
  def perform(entity_id, student_id)
    super do
      undiscardable_absence_justifications(student_id).each do |absence_justification|
        absence_justification.discarded_at = nil
        absence_justification.save!(validate: false)
      end
    end
  end

  private

  def undiscardable_absence_justifications(student_id)
    classroom_id_column = 'absence_justifications.classroom_id'
    start_at_column = 'absence_justifications.absence_date'
    end_at_column = 'absence_justifications.absence_date_end'

    AbsenceJustification.with_discarded.discarded.by_student_id(student_id).where(
      exists_enrollment_by_date_column(
        classroom_id_column,
        start_at_column,
        end_at_column
      ),
      student_id: student_id
    )
  end
end
