module IeducarApi::Students
  class Students < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Aluno',
        resource: 'todos-alunos'
      )

      super
    end
  end
end
