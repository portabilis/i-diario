class ConceptualExamsUndiscardWorker < BaseStudentDependenciesDiscarderWorker
  def perform(entity_id, student_id)
    super do
      undiscardable_conceptual_exams(student_id).each do |conceptual_exam|
        next if conceptual_exam_exists?(conceptual_exam, student_id)

        conceptual_exam.discarded_at = nil
        conceptual_exam.save!(validate: false)
      end
    end
  end

  private

  def undiscardable_conceptual_exams(student_id)
    classroom_id_column = 'conceptual_exams.classroom_id'
    step_number_column = 'conceptual_exams.step_number'
    start_at_column = 'step.start_at'
    end_at_column = 'step.end_at'

    ConceptualExam.with_discarded.discarded.joins(
      joins_step_by_step_number_and_classroom(
        classroom_id_column,
        step_number_column
      )
    ).by_student_id(student_id).where(
      exists_enrollment_by_date_column(
        classroom_id_column,
        start_at_column,
        end_at_column
      ),
      student_id: student_id
    )
  end

  def conceptual_exam_exists?(conceptual_exam, student_id)
    ConceptualExam.by_classroom_id(conceptual_exam.classroom_id)
                  .by_student_id(student_id)
                  .by_step_number(conceptual_exam.step_number).exists?
  end
end
