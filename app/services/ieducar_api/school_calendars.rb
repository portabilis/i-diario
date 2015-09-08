module IeducarApi
  class SchoolCalendars < Base
    def fetch(params = {})
      raise ApiError.new('É necessário informar o ano') if params[:ano].blank?

      params.reverse_merge!(path: 'module/Api/Escola', resource: 'etapas-por-escola')

      super
    end
  end
end