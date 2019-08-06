class AvaliationExemptionsDiscardWorker < BaseStudentDependenciesDiscarderWorker
  def perform(entity_id, student_enrollment_id)
    super do
      discardable_avaliation_exemptions(student_enrollment_id).discard_all
    end
  end

  private

  def discardable_avaliation_exemptions(student_enrollment_id)
    student_id = find_student(student_enrollment_id)
    classroom_id_column = 'avaliations.classroom_id'
    date_column = 'avaliations.test_date'

    AvaliationExemption.joins(:avaliation).by_student(student_id).where(
      not_exists_enrollment_by_date_column(
        classroom_id_column,
        date_column
      ),
      student_id: student_id
    )
  end
end
