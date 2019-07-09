module IeducarApi
  class ExamRules < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Regra',
        resource: 'regras'
      )

      super
    end
  end
end
