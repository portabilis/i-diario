module IeducarApi
  class GradeExamRules < Base
    def fetch(params = {})
      params[:path] = 'module/Api/Regra'
      params[:resource] = 'regra-serie-ano'

      raise ApiError, 'É necessário informar o ano' if params[:ano].blank?

      super
    end
  end
end
