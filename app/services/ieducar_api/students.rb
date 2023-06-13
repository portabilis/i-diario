module IeducarApi
  class Students < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Aluno',
        resource: 'todos-alunos'
      )

      super
    end

    def fetch_by_cpf(document, student_code)
      fetch(
        resource: 'alunos_by_guardian_cpf',
        cpf: document,
        aluno_id: student_code
      )
    end
  end
end
