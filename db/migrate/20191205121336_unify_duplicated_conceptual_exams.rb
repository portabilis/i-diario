class UnifyDuplicatedConceptualExams < ActiveRecord::Migration[4.2]
  def change
    conceptual_exams = ConceptualExam.joins(
      :classroom
    ).where(
      classrooms: { year: 2019 }
    ).group(
      :classroom_id, :student_id, :step_number
    ).having(
      'COUNT(1) > 1'
    ).pluck(
      'MAX(conceptual_exams.id)', :classroom_id, :student_id, :step_number
    )

    conceptual_exams.each do |correct_id, classroom_id, student_id, step_number|
      current_conceptual_exam_values = ConceptualExamValue.by_conceptual_exam_id(correct_id)
      duplicated_conceptual_exams = ConceptualExam.where(
        classroom_id: classroom_id,
        student_id: student_id,
        step_number: step_number
      ).where.not(id: correct_id)

      duplicated_conceptual_exams.each do |conceptual_exam|
        duplicated_conceptual_exam_values = ConceptualExamValue.by_conceptual_exam_id(conceptual_exam.id)

        duplicated_conceptual_exam_values.each do |conceptual_exam_value|
          current_conceptual_exam_value = current_conceptual_exam_values.find_by(
            discipline_id: conceptual_exam_value.discipline_id
          )

          if current_conceptual_exam_value.blank?
            conceptual_exam_value.without_auditing do
              conceptual_exam_value.update(conceptual_exam_id: correct_id)
            end
          else
            value = [current_conceptual_exam_value.value, conceptual_exam_value.value].compact.max
            current_conceptual_exam_value.value = value
            if current_conceptual_exam_value.changed?
              current_conceptual_exam_value.without_auditing do
                current_conceptual_exam_value.save!
              end
            end
          end
        end

        conceptual_exam.discarded_at = Time.current
        conceptual_exam.without_auditing do
          conceptual_exam.save!(validate: false)
        end
      end
    end
  end
end
