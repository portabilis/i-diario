class DescriptiveExamStudentsUndiscardWorker < BaseStudentDependenciesDiscarderWorker
  def perform(entity_id, student_id)
    super do
      undiscardable_descriptive_exam_students(student_id).each do |descriptive_exam_student|
        next if descriptive_exam_student_exists?(descriptive_exam_student, student_id)

        descriptive_exam_student.discarded_at = nil
        descriptive_exam_student.save!(validate: false)
      end
    end
  end

  private

  def undiscardable_descriptive_exam_students(student_id)
    classroom_id_column = 'descriptive_exams.classroom_id'
    step_number_column = 'descriptive_exams.step_number'
    start_at_column = 'step.start_at'
    end_at_column = 'step.end_at'

    DescriptiveExamStudent.with_discarded
                          .discarded
                          .joins(:descriptive_exam)
                          .joins(
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

  def descriptive_exam_student_exists?(descriptive_exam_student, student_id)
    DescriptiveExamStudent.by_descriptive_exam_id(descriptive_exam_student.descriptive_exam_id)
                          .by_student_id(student_id).exists?
  end
end
