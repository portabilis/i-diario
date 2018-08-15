class ComplementaryExamSettingDecorator
  include Decore
  include Decore::Proxy
  include ActionView::Helpers::TagHelper

  def grades_labels
    return unless component.grades

    component.grades.map do |u|
      content_tag(:p, content_tag(:span, u, class: 'label label-info label-list'))
    end.join.html_safe
  end
end
