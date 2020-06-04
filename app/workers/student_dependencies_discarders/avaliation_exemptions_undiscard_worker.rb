class AvaliationExemptionsUndiscardWorker < BaseStudentDependenciesDiscarderWorker
  def perform(entity_id, student_id)
    super do
      undiscardable_avaliation_exemptions(student_id).each do |avaliation_exemption|
        avaliation_exemption.discarded_at = nil
        avaliation_exemption.save!(validate: false)
      end
    end
  end

  private

  def undiscardable_avaliation_exemptions(student_id)
    classroom_id_column = 'avaliations.classroom_id'
    date_column = 'avaliations.test_date'

    AvaliationExemption.with_discarded.discarded.joins(:avaliation).by_student(student_id).where(
      exists_enrollment_by_date_column(
        classroom_id_column,
        date_column
      ),
      student_id: student_id
    )
  end
end
