class CustomRoundingTableDecorator
  include Decore
  include Decore::Proxy
  include ActionView::Helpers::TagHelper

  def unities_labels
    return unless component.unities

    component.unities.map do |u|
      content_tag(:p, content_tag(:span, u, class: 'label label-info label-list'))
    end.join.html_safe
  end

  def grades_labels
    return unless component.grades

    component.grades.map do |u|
      content_tag(:p, content_tag(:span, u, class: 'label label-info label-list'))
    end.join.html_safe
  end
end
