class AdministrativeToolsIntegrator
  attr_accessor :messages
  NOVO_EDUCACAO = 3

  def initialize(entity_name)
    @entity_name = entity_name
  end

  def fetch_messages!
    @messages = request_messages!
  end

  def request_messages!
    #FIXME Ajustar funcionalidade pois está quebrando alguns testes de aceitação
    # begin
    #   response = RestClient.get endpoint, { params: { product: NOVO_EDUCACAO } }
    #   JSON.parse(response)
    # rescue
    # end
    []
  end

  private

  def endpoint
    #TODO Mudar assim que for criado um ambiente correto de produção
    'http://portabilis-adm.herokuapp.com/api/v1/messages'
  end
end
