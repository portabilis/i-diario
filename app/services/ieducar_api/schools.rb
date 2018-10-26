# encoding: utf-8
module IeducarApi
  class Schools < Base
    def fetch_with_vacancy(params = {})
      params.merge!(path: "module/Api/Escola", resource: "escolas")

      raise ApiError.new("É necessário informar pelo menos um ano") if params[:ano].blank?
      raise ApiError.new("É necessário informar pelo menos um curso") if params[:curso_id].blank?
      raise ApiError.new("É necessário informar pelo menos uma serie") if params[:serie_id].blank?
      raise ApiError.new("É necessário informar pelo menos uma turma_turno_id") if params[:turma_turno_id].blank?

      fetch(params)
    end

    def fetch_all(params = {})
      params.merge!(path: "module/Api/Escola", resource: "info-escolas")

      fetch(params)
    end
  end
end
