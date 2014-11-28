# encoding: utf-8
module IeducarApi
  class Lectures < Base
    def fetch(params = {})
      params.reverse_merge!(path: "module/Api/Curso", resource: "cursos", get_series: true)

      raise ApiError.new("É necessário informar pelo menos uma escola: escola_id") if params[:escola_id].blank?

      super
    end
  end
end
