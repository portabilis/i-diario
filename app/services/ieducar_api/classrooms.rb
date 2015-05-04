# encoding: utf-8
module IeducarApi
  class Classrooms < Base
    def fetch(params = {})
      params.reverse_merge!(path: "module/Api/Turma", resource: "turmas-por-escola")

      raise ApiError.new("É necessário informar o ano") if params[:ano].blank?
      super
    end
  end
end
