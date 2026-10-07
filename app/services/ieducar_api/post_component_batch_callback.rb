module IeducarApi
  # Avisa o i-Educar do resultado da remoção de componentes em lote pedida por ele
  # (POST /api/v2/component-batch-callback).
  class PostComponentBatchCallback < V2Base
    POST_PATH = '/api/v2/component-batch-callback'.freeze
    LOG_PREFIX = '[component-batch-callback]'.freeze
    # O endpoint responde 200, inclusive quando a operação não está mais em execução no i-Educar.
    SAVED_STATUS = 200
    SUCCESS_MESSAGE = 'Callback processado com sucesso.'.freeze
    FIELDS = { operation_id: 'a operação' }.freeze
    LOG_LABELS = { operation_id: 'operação', success: 'sucesso', deleted: 'removidos' }.freeze

    protected

    def payload_for(params)
      payload = super.merge(success: params[:success] == true)
      payload[:deleted] = integer_from(params, :deleted, 'a quantidade removida') if params[:deleted].present?
      payload[:error] = params[:error].to_s if params[:error].present?

      payload
    end
  end
end
