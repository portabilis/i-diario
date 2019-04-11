module IeducarApi
  class SpecificSteps < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Etapas',
        resource: 'etapas-especificas'
      )

      super
    end
  end
end
