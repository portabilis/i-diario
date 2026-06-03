module ConceptualExamHelper
  def conceptual_exam_label(status)
    '' if status.blank?

    case status
    when ConceptualExamStatus::INCOMPLETE
      'label label-warning'
    when ConceptualExamStatus::COMPLETE
      'label label-success'
    end
  end

  def any_student_exempted_from_discipline?
    @conceptual_exam.conceptual_exam_values.any? { |value| value.exempted_discipline.to_s == 'true' }
  end

  def any_student_in_dependence?
    conceptual_exam_dependence_discipline_ids.any?
  end

  def conceptual_exam_dependence_discipline_ids
    return @conceptual_exam_dependence_discipline_ids if defined?(@conceptual_exam_dependence_discipline_ids)

    @conceptual_exam_dependence_discipline_ids =
      if @conceptual_exam&.student_id && @conceptual_exam.classroom
        StudentEnrollmentDependence.discipline_ids_for(
          @conceptual_exam.student_id, @conceptual_exam.classroom_id
        ).to_set
      else
        Set.new
      end
  end

  def ordered_conceptual_exam_values
    @conceptual_exam.conceptual_exam_values
                    .sort_by { |conceptual_exam_value|
                      [
                        conceptual_exam_value.discipline.sequence.to_i,
                        conceptual_exam_value.discipline.description
                      ]
                    }
                    .group_by { |conceptual_exam_value|
                      conceptual_exam_value.discipline.knowledge_area
                    }
                    .sort_by { |knowledge_area, conceptual_exam_values|
                      [
                        knowledge_area.sequence.to_i,
                        knowledge_area.description
                      ]
                    }
  end

  def any_conceptual_exam_with_exempted_student?
    @conceptual_exams.any? do |conceptual_exam|
      conceptual_exam.conceptual_exam_values.any? { |value| value.exempted_discipline.to_s == 'true' }
    end
  end

  def first_conceptual_exam_by_params(conceptual_exam, discipline_id)
    ConceptualExam.where(
      step_number: conceptual_exam.step_number,
      classroom_id: conceptual_exam.classroom_id
    ).by_discipline(discipline_id).first
  end
end
