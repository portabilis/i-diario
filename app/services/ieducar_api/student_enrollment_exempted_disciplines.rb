
module IeducarApi
  class StudentEnrollmentExemptedDisciplines < Base
    def fetch(params = {})
      params.reverse_merge!(path: 'module/Api/Matricula', resource: 'dispensa-disciplina')

      super
    end
  end
end
