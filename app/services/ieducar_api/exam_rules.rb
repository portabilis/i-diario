module IeducarApi
  class ExamRules < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Regra',
        resource: 'regras'
      )

      raise ApiError, 'É necessário informar o ano' if params[:ano].blank?

      super
    end
  end
end
