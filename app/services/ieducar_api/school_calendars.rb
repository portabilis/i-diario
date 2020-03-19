module IeducarApi
  class SchoolCalendars < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Escola',
        resource: 'etapas-por-escola'
      )

      raise ApiError, 'É necessário informar o ano' if params[:ano].blank? && params[:classroom_steps]
      raise ApiError, 'É necessário informar pelo menos uma escola' if params[:escola].blank?

      super
    end
  end
end
