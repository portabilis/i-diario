module ConceptualExamsInBatchs
  class Base
    def find_or_initialize_conceptual_exam(student_id, recorded_at, classroom, teacher_id, user, step)
      conceptual_exam = find_conceptual_exam(student_id, step.id, classroom.id)

      return nil unless StudentEnrollment.by_student(student_id)
                                         .by_classroom(classroom.id)
                                         .by_date(recorded_at)
                                         .exists?

      if conceptual_exam.blank?
        conceptual_exam = ConceptualExam.new(
          unity_id: classroom.unity_id,
          classroom_id: classroom.id,
          student_id: student_id,
          recorded_at: recorded_at.to_date,
          step_id: step.id.to_i,
          step_number: step.step_number,
          teacher_id: teacher_id,
          current_user: user
        )
      end

      conceptual_exam
    end

    def find_conceptual_exam(student_id, step_id, classroom_id)
      classroom = Classroom.find(classroom_id)

      ConceptualExam.by_classroom(classroom_id)
                    .by_step_id(classroom, step_id)
                    .by_student_id(student_id)
                    .first
    end
  end
end
