# encoding: utf-8
module IeducarApi
  class SpecificSteps < Base
    def fetch(params = {})
      params.reverse_merge!(path: "module/Api/Etapas", resource: "etapas-especificas-por-disciplina")
      super
    end
  end
end
