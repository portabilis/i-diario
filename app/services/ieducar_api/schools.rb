module IeducarApi
  class Schools < Base
    def fetch_with_vacancy(params = {})
      params[:path] = 'module/Api/Escola'
      params[:resource] = 'escolas'

      raise ApiError, 'É necessário informar pelo menos um ano' if params[:ano].blank?
      raise ApiError, 'É necessário informar pelo menos um curso' if params[:curso_id].blank?
      raise ApiError, 'É necessário informar pelo menos uma série' if params[:serie_id].blank?
      raise ApiError, 'É necessário informar pelo menos um turno de turma' if params[:turma_turno_id].blank?

      fetch(params)
    end

    def fetch_all(params = {})
      params[:path] = 'module/Api/Escola'
      params[:resource] = 'info-escolas'

      fetch(params)
    end
  end
end
