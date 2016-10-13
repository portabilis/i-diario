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
    case object.source_type
    when "***REMOVED***"
      routes.***REMOVED***_path
    when "Message"
      routes.message_path(object.source_id)
    when "***REMOVED***"
      routes.***REMOVED***_movements_report_viewer_path(object.source)
    else
      ""
    end
  end
end
