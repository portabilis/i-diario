# encoding: utf-8
module IeducarApi
  class ExamRules < Base
    def fetch(params = {})
      params.reverse_merge!(path: "module/Api/Regra", resource: "regras")

      raise ApiError.new("É necessário informar o ano") if params[:ano].blank?
      super
    end
  end
end
