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
    else
      ""
    end
  end
end
