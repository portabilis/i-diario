module IeducarApi
  class TeacherUnifications < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Servidor',
        resource: 'unificacoes'
      )

      super
    end
  end
end
