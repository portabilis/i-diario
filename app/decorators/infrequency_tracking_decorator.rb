class InfrequencyTrackingDecorator
  include Decore
  include Decore::Proxy
  include ActionView::Helpers::TagHelper

  def notification_type
    content_tag(
      :p,
      content_tag(
        :span,
        component.notification_type_humanize,
        class: 'label label-info label-list'
      )
    )
  end

  def self.data_for_select2
    items = InfrequencyTrackingTypes.to_a.map { |text, value| { id: value, name: text, text: text } }

    insert_empty_element(items) if items.any?

    items.to_json
  end

  def self.insert_empty_element(items)
    empty_element = { id: 'empty', name: '<option></option>', text: '' }
    items.insert(0, empty_element)
  end
end
