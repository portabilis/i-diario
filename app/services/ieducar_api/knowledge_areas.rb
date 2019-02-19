module IeducarApi
  class KnowledgeAreas < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/AreaConhecimento',
        resource: 'areas-de-conhecimento'
      )

      super
    end
  end
end
