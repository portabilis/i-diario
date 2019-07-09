module IeducarApi
  class Classrooms < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Turma',
        resource: 'turmas-por-escola'
      )

      raise ApiError, 'É necessário informar o ano' if params[:ano].blank?
      raise ApiError, 'É necessário informar pelo menos uma escola' if params[:escola].blank?

      super
    end
  end
end
