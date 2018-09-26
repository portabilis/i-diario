class SystemNotificationRouter
  attr_accessor :object, :routes

  def self.path(object)
    new(object).path
  end

  def initialize(object, routes = ::Rails.application.routes.url_helpers)
    self.object = object
    self.routes = routes
  end

  def path
    return "" unless object.source
    case object.source_type
    when "Message"
      routes.message_path(object.source_id)
    when "***REMOVED***"
      routes.***REMOVED***_movements_report_viewer_path(object.source)
    when "***REMOVED***Request"
      routes.material_request_path(object.source, format: :pdf)
    when "***REMOVED***"
      routes.edit_service_request_path(object.source)
    when "MaintenanceAdjustment"
      routes.maintenance_adjustments_path
    else
      ""
    end
  end
end
