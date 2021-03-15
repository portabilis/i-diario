class ComplementaryExamSettingDecorator
  include Decore
  include Decore::Proxy
  include ActionView::Helpers::TagHelper

  def grades_labels
    return unless component.grades

    component.grades.map do |grade|
      grade = "#{grade.description} - #{grade.course.description}"

      content_tag(:p, content_tag(:span, grade, class: 'label label-info label-list'))
    end.join.html_safe
  end
end
