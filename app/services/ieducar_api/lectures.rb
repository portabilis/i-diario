module IeducarApi
  class Lectures < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Curso',
        resource: 'cursos'
      )

      super
    end
  end
end
