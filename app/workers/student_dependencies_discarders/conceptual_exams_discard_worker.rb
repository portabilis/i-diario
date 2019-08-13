class ConceptualExamsDiscardWorker < BaseStudentDependenciesDiscarderWorker
  def perform(entity_id, student_id)
    super do
      discardable_conceptual_exams(student_id).each do |conceptual_exam|
        conceptual_exam.discarded_at = Time.current
        conceptual_exam.save!(validate: false)
      end
    end
  end

  private

  def discardable_conceptual_exams(student_id)
    classroom_id_column = 'conceptual_exams.classroom_id'
    step_number_column = 'conceptual_exams.step_number'
    start_at_column = 'step.start_at'
    end_at_column = 'step.end_at'

    ConceptualExam.joins(
      joins_step_by_step_number_and_classroom(
        classroom_id_column,
        step_number_column
      )
    ).by_student_id(student_id).where(
      not_exists_enrollment_by_date_column(
        classroom_id_column,
        start_at_column,
        end_at_column
      ),
      student_id: student_id
    )
  end
end
