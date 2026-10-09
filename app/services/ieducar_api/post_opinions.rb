module IeducarApi
  # Base dos envios de parecer descritivo de um aluno pela API v2 do i-Educar. Cada tipo de parecer
  # (OpinionTypes) tem o próprio endpoint, e as subclasses definem o caminho e os campos.
  #
  # `parecer` vai sempre no payload: o i-Educar exige o campo e trata o texto vazio como pedido
  # para limpar o parecer já lançado.
  class PostOpinions < V2Base
    SUCCESS_MESSAGE = 'Pareceres postados com sucesso!'.freeze

    # O payload diz o tipo de parecer: os anuais não têm etapa, e os gerais não têm componente.
    def self.for_payload(configuration, params)
      params = params.with_indifferent_access
      by_step = params[:etapa].present?
      by_discipline = params[:componente_id].present?

      api_class =
        if by_step
          by_discipline ? PostOpinionsByStepAndDiscipline : PostOpinionsByStep
        else
          by_discipline ? PostOpinionsByYearAndDiscipline : PostOpinionsByYear
        end

      api_class.new(configuration)
    end

    protected

    def payload_for(params)
      super.merge(parecer: params[:parecer].to_s)
    end

    private

    def validate!(params)
      super

      raise Base::ApiError, 'É necessário informar o parecer' unless params.key?(:parecer)
    end
  end
end
