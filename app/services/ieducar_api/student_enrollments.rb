# encoding: utf-8
module IeducarApi
  class StudentEnrollments < Base
    def fetch(params = {})
      params.reverse_merge!(path: "module/Api/Matricula", resource: "movimentacao-enturmacao")

      raise ApiError.new("É necessário informar o ano") if params[:ano].blank?
      super
    end
  end
end
