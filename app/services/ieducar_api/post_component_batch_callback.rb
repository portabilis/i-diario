module IeducarApi
  class PostComponentBatchCallback < Base
    def send_post(params = {})
      params.reverse_merge!(
        path: 'module/Api/Diario',
        resource: 'component-batch-callback',
        oper: 'post'
      )

      super
    end
  end
end
