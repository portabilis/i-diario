module IeducarApi
  class SchoolCalendars < Base
    def fetch(params = {})
      params.reverse_merge!(path: 'module/Api/Escola', resource: 'etapas-por-escola')

      super
    end
  end
end
