class TestSettingDecorator
  include Decore
  include Decore::Proxy
  include ActionView::Helpers::TagHelper

  def unities_labels
    return unless component.general_by_school?
    return buil_tag('Todas') if component.unities.size == Unity.with_api_code.count

    component.unities.map { |unity_id| buil_tag(Unity.with_discarded.find(unity_id).name) }.join.html_safe
  end

  def buil_tag(text)
    content_tag(:p, content_tag(:span, text, class: 'label label-info label-list'))
  end
end
