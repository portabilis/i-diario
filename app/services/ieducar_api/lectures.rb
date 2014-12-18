# encoding: utf-8
module IeducarApi
  class Lectures < Base
    def fetch(params = {})
      params.reverse_merge!(path: "module/Api/Curso", resource: "cursos", get_series: true)

      super
    end
  end
end
