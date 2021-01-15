class LearningObjectivesAndSkillDecorator
  include Decore
  include Decore::Proxy
  include ActionView::Helpers::TagHelper

  def grades_labels
    return unless component.grades

    component.grades.map { |grade|
      content_tag(:p, content_tag(:span, localized_grade(grade), class: 'label label-info label-list'))
    }.join.html_safe
  end

  private

  def localized_grade(grade)
    return ChildEducations.t(grade) if component.child_school?

    ElementaryEducations.t(grade)
  end
end
