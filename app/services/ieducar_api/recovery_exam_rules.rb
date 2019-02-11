module IeducarApi
  class RecoveryExamRules < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Regra',
        resource: 'regras-recuperacao'
      )

      super
    end
  end
end
