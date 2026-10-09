require 'rails_helper'

# Defesa em profundidade: cabeçalhos de segurança em todas as respostas. Os padrões do Rails
# (X-Frame-Options, X-Content-Type-Options: nosniff) são complementados por Referrer-Policy e por
# uma Content-Security-Policy em modo report-only.
RSpec.describe 'security response headers', type: :request do
  before { host! 'test.host' }

  it 'sends Referrer-Policy on responses' do
    get '/usuarios/logar'

    expect(response.headers['Referrer-Policy']).to eq('strict-origin-when-cross-origin')
  end

  it 'sends a report-only Content-Security-Policy' do
    get '/usuarios/logar'

    expect(response.headers['Content-Security-Policy-Report-Only']).to include("default-src 'self'")
    expect(response.headers).not_to have_key('Content-Security-Policy')
  end

  it 'keeps the Rails defaults (nosniff, frame options)' do
    get '/usuarios/logar'

    expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
    expect(response.headers['X-Frame-Options']).to eq('SAMEORIGIN')
  end
end
