class DescriptiveExamStudentsDiscardWorker < BaseStudentDependenciesDiscarderWorker
  def perform(entity_id, student_id)
    super do
      discardable_descriptive_exam_students(student_id).each do |descriptive_exam_student|
        descriptive_exam_student.discarded_at = Time.current
        descriptive_exam_student.save!(validate: false)
      end
    end
  end

  private

  def discardable_descriptive_exam_students(student_id)
    classroom_id_column = 'descriptive_exams.classroom_id'
    step_number_column = 'descriptive_exams.step_number'
    start_at_column = 'step.start_at'
    end_at_column = 'step.end_at'

    DescriptiveExamStudent.joins(:descriptive_exam)
                          .joins(
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
