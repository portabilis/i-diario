module IeducarApi
  class StudentUnifications < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Aluno',
        resource: 'unificacao-alunos'
      )

      raise ApiError, 'É necessário informar pelo menos uma escola' if params[:escola].blank?

      super
    end
  end
end
