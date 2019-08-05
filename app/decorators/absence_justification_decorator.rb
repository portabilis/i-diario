class AbsenceJustificationDecorator
  include Decore
  include ActionView::Helpers::TagHelper

  def author(current_teacher)
    PlanAuthorFetcher.new(component, current_teacher).author
  end

  def students_labels
    return unless component.students

    component.students.map { |student|
      content_tag(:p, content_tag(:span, student, class: 'label label-info label-list'))
    }.join.html_safe
  end
end
