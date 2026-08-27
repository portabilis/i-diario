# Autenticação da API v2 pelo token do i-Educar: o header `token` precisa bater
# com o `api_security_token` da configuração da entidade de teste.
RSpec.shared_context 'api v2 ieducar token' do
  let(:api_token) { SecureRandom.hex(15) }

  around(:each) do |example|
    Entity.find_by_domain('test.host').using_connection do
      example.run
    end
  end

  before do
    IeducarApiConfiguration.current.update!(
      url: 'http://test.ieducar.com.br',
      token: '8IOwGIjiHvbeTklgwo10yVLgwDhhvs',
      secret_token: '5y8cfq31oGvFdAlGMCLIeSKdfc8pUC',
      unity_code: 1,
      api_security_token: api_token
    )
    request.headers['token'] = api_token
  end
end
