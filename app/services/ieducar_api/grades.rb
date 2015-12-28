module IeducarApi
  class Grades < Base
    def fetch(params = {})
      params.merge!(path: "module/Api/Serie", resource: "series")

      raise ApiError.new("É necessário informar pelo menos uma escola: escola_id") if params[:escola_id].blank?
      raise ApiError.new("É necessário informar pelo menos um curso: curso_id") if params[:curso_id].blank?

      super
    end
  end
end
