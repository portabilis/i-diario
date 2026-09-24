# Contrato da fronteira de entrada compartilhada pelas consultas por unidade e
# período (Api::V2::UnityPeriodParams). Quem inclui informa o service ao qual
# a action delega; os números ficam nos specs de service.
RSpec.shared_examples 'an api v2 unity period endpoint' do |service_class|
  let(:unity) { create(:unity, api_code: 'unity-1') }
  let(:other_unity) { create(:unity, api_code: 'unity-2') }
  let(:valid_params) { { unity_api_code: unity.api_code, start_at: '2026-06-01', end_at: '2026-06-30' } }

  def get_index(overrides = {})
    get :index, params: { format: :json, locale: 'en' }.merge(valid_params).merge(overrides)
  end

  def error_message
    JSON.parse(response.body)['error']
  end

  it 'returns 401 without a valid token' do
    request.headers['token'] = 'invalid'

    get_index

    expect(response).to have_http_status(:unauthorized)
  end

  it 'returns 422 naming the missing parameters' do
    get :index, params: { format: :json, locale: 'en' }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(error_message).to eq('Os seguintes parâmetros são obrigatórios: unity_api_code, start_at, end_at')
  end

  it 'returns 422 when a date does not exist' do
    get_index(start_at: '2026-13-01')

    expect(response).to have_http_status(:unprocessable_entity)
    expect(error_message).to eq('Os parâmetros start_at e end_at devem estar no formato AAAA-MM-DD')
  end

  # "01/06/2026" seria lido como 1º de junho por String#to_date, mas quem chama
  # pode ter querido 6 de janeiro: formato ambíguo é rejeitado, não adivinhado.
  it 'returns 422 when a date is not ISO 8601' do
    get_index(end_at: '30/06/2026')

    expect(response).to have_http_status(:unprocessable_entity)
    expect(error_message).to eq('Os parâmetros start_at e end_at devem estar no formato AAAA-MM-DD')
  end

  it 'returns 422 when start_at is after end_at' do
    get_index(start_at: '2026-07-01', end_at: '2026-06-30')

    expect(response).to have_http_status(:unprocessable_entity)
    expect(error_message).to eq('O parâmetro start_at deve ser anterior ou igual a end_at')
  end

  # O período é um só; a lista de unidades é que aceita vários valores.
  it 'returns 422 when the period is sent more than once' do
    get_index(start_at: %w[2026-06-01 2026-06-02])

    expect(response).to have_http_status(:unprocessable_entity)
    expect(error_message).to eq('Os seguintes parâmetros aceitam um único valor: start_at')
  end

  # Unidade desconhecida não é erro: quem consome varre a rede pela lista de
  # escolas do i-Educar, e uma escola nova aparece lá antes de a sincronização
  # criá-la aqui. Responder erro derrubaria a varredura inteira.
  it 'delegates with no unity when the unity does not exist' do
    expect(service_class).to receive(:call).with(
      unities: [],
      start_at: Date.new(2026, 6, 1),
      end_at: Date.new(2026, 6, 30)
    ).and_return([])

    get_index(unity_api_code: 'unknown')

    expect(response).to have_http_status(:ok)
  end

  it 'keeps the known unities when one of them does not exist' do
    expect(service_class).to receive(:call) do |args|
      expect(args[:unities]).to eq([unity])
      []
    end

    get_index(unity_api_code: [unity.api_code, 'unknown'])

    expect(response).to have_http_status(:ok)
  end

  it 'delegates to the service with the resolved unity and the parsed dates' do
    expect(service_class).to receive(:call).with(
      unities: [unity],
      start_at: Date.new(2026, 6, 1),
      end_at: Date.new(2026, 6, 30)
    ).and_return([{ unity_api_code: 'unity-1' }])

    get_index

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq([{ 'unity_api_code' => 'unity-1' }])
  end

  it 'accepts more than one unity in the same request' do
    expect(service_class).to receive(:call) do |args|
      expect(args[:unities]).to match_array([unity, other_unity])
      []
    end

    get_index(unity_api_code: [unity.api_code, other_unity.api_code])

    expect(response).to have_http_status(:ok)
  end
end
