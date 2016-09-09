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
    begin
      response = RestClient.get endpoint, { params: { product: NOVO_EDUCACAO } }
      JSON.parse(response)
    rescue
      []
    end
  end

  private

  def endpoint
    'http://***REMOVED***/api/v1/messages'
  end
end
