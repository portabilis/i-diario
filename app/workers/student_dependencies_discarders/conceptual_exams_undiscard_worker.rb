class ConceptualExamsUndiscardWorker < BaseStudentDependenciesDiscarderWorker
  def perform(entity_id, student_id)
    super do
      undiscardable_conceptual_exams(student_id).each do |conceptual_exam|
        existing_exam = existing_exam(conceptual_exam, student_id)

        if existing_exam.present?
          adjust_values_to_exam(existing_exam, conceptual_exam)
        else
          conceptual_exam.discarded_at = nil
          conceptual_exam.save!(validate: false)
        end
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

  def existing_exam(conceptual_exam, student_id)
    ConceptualExam.find_by(
      classroom_id: conceptual_exam.classroom_id,
      student_id: student_id,
      step_number: conceptual_exam.step_number
    )
  end

  def adjust_values_to_exam(correct_exam, old_exam)
    old_exam.conceptual_exam_values.each do |value|
      next if correct_exam.conceptual_exam_values.find_by(discipline_id: value.discipline_id).present?

      value.update(conceptual_exam_id: correct_exam.id)
    end
  end
end
