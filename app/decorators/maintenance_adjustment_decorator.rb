class MaintenanceAdjustmentDecorator
  include Decore
  include Decore::Proxy
  include ActionView::Helpers::TagHelper

  def unities_labels
    return unless component.unities

    component.unities.map do |unity|
      content_tag(:p, content_tag(:span, unity, class: 'label label-info label-list'))
    end.join.html_safe
  end

  def status_labels
    return unless component.status

    spin = case component.status
      when MaintenanceAdjustmentStatus::IN_PROGRESS then
        content_tag(:span, content_tag(:i, '', class: 'fa fa-cog fa-spin', style: 'margin-right: 3px'))
      else ''
    end

    status_class = case component.status
      when MaintenanceAdjustmentStatus::PENDING then 'info'
      when MaintenanceAdjustmentStatus::IN_PROGRESS then 'warning'
      when MaintenanceAdjustmentStatus::COMPLETED then 'success'
      when MaintenanceAdjustmentStatus::ERROR then 'danger'
    end

    html_options = {
      class: 'label label-list label-' << status_class,
      :'data-column' => 'situation',
      :'data-value' => component.status,
      :'data-id' => component.id
    }
    html_options[:title] = component.error_message if component.error? && component.error_message.present?

    content_tag(
      :p,
      spin << MaintenanceAdjustmentStatus.t(component.status),
      html_options
    ).html_safe
  end
end
