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
      # Quando for feito a pagina de exibicao
      # de ocorrencia disciplinar a linha abaixo deve ser descomentada
      # routes.disciplinary_occurrence_path(object.source_id)
      ""
    else
      ""
    end
  end
end
