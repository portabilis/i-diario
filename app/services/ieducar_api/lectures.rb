module IeducarApi
  class Lectures < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Curso',
        resource: 'cursos'
      )

      raise ApiError, 'É necessário informar pelo menos uma escola' if params[:escola_id].blank?

      super
    end
  end
end
