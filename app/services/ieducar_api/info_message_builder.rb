module IeducarApi
  class InfoMessageBuilder
    def initialize(info)
      @info = info
      @students_cache = {}
      @disciplines_cache = {}
      @classrooms_cache = {}
    end

    def build
      message = ''

      message += "Turma: #{classroom(info['classroom'])};<br>" if info.key?('classroom')
      message += "Aluno: #{student(info['student'])};<br>" if info.key?('student')
      message += "Componente curricular: #{discipline(info['discipline'])};<br>" if info.key?('discipline')

      message
    end

    private

    attr_reader :info, :students_cache, :disciplines_cache, :classrooms_cache

    def student(api_code)
      students_cache[api_code] ||= Student.find_by(api_code: api_code).try(:name)
    end

    def discipline(api_code)
      disciplines_cache[api_code] ||= Discipline.find_by(api_code: api_code).try(:description)
    end

    def classroom(api_code)
      classrooms_cache[api_code] ||= Classroom.find_by(api_code: api_code).try(:description)
    end
  end
end
