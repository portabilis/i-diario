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
end
