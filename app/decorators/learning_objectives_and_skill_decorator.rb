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
    return GroupChildEducations.t(grade) if group_children_education? && component.child_school?

    return ChildEducations.t(grade) if component.child_school?

    return AdultAndYouthEducations.t(grade) if component.adult_and_youth_education?

    ElementaryEducations.t(grade)
  end

  def group_children_education?
    @group_children_education ||= GeneralConfiguration.current.group_children_education
  end
end
