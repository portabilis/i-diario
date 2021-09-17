module IeducarApi
  class SchoolCalendarDisciplineGrades < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Escola',
        resource: 'escola-serie-disciplinas-anos-letivos'
      )
      raise ApiError, 'É necessário informar pelo menos uma escola' if params[:escola].blank?

      super
    end
  end
end
