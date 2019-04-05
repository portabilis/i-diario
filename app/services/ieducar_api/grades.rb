module IeducarApi
  class Grades < Base
    def fetch(params = {})
      params[:path] = 'module/Api/Serie'
      params[:resource] = 'series'

      raise ApiError, 'É necessário informar pelo menos uma escola' if params[:escola_id].blank?

      super
    end
  end
end
