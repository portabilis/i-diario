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

  def courses_labels
    return unless component.courses

    component.courses.map do |u|
      content_tag(:p, content_tag(:span, u, class: 'label label-info label-list'))
    end.join.html_safe
  end

  def grades_labels
    return unless component.grades

    component.grades.map do |u|
      content_tag(:p, content_tag(:span, u, class: 'label label-info label-list'))
    end.join.html_safe
  end

  def rounded_avaliations_labels
    return if component.rounded_avaliations.blank?

    component.rounded_avaliations.map { |rounded_avaliation|
      value = RoundedAvaliations.to_hash.key(rounded_avaliation)

      content_tag(:p, content_tag(:span, value, class: 'label label-info label-list'))
    }.join.html_safe
  end
end
