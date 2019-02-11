module IeducarApi
  class SpecificStepClassrooms < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Etapas',
        resource: 'turmas-com-etapas-especificas'
      )

      super
    end
  end
end
