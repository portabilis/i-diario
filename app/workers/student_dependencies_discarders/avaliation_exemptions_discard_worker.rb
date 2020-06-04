class AvaliationExemptionsDiscardWorker < BaseStudentDependenciesDiscarderWorker
  def perform(entity_id, student_id)
    super do
      discardable_avaliation_exemptions(student_id).each do |avaliation_exemption|
        avaliation_exemption.discarded_at = Time.current
        avaliation_exemption.save!(validate: false)
      end
    end
  end

  private

  def discardable_avaliation_exemptions(student_id)
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
