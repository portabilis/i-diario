module IeducarApi
  class Grades < Base
    def fetch(params = {})
      params[:path] = 'module/Api/Serie'
      params[:resource] = 'series'

      raise ApiError, 'É necessário informar pelo menos uma escola' if params[:escola_id].blank?
      raise ApiError, 'É necessário informar pelo menos um curso' if params[:curso_id].blank?

      super
    end
  end
end
