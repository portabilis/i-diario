require 'rails_helper'

# Defesa em profundidade: limita tentativas nos endpoints de autenticação.
# Recuperação de senha por IP; login pela credencial (evita bloquear a escola inteira, que
# costuma acessar por trás de um único IP).
RSpec.describe 'rack-attack throttling', type: :request do
  before do
    @original_store = Rack::Attack.cache.store
    # O cache de teste é :null_store; usa memória para os contadores do throttle valerem.
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    host! 'test.host'
  end

  after do
    Rack::Attack.cache.store = @original_store
  end

  it 'throttles password reset requests by IP after 5 per minute' do
    6.times { post '/usuarios/senha', params: { user: { email: 'atacante@example.com' } } }

    expect(response).to have_http_status(:too_many_requests)
  end

  it 'does not throttle password reset under the limit' do
    3.times { post '/usuarios/senha', params: { user: { email: 'atacante@example.com' } } }

    expect(response).not_to have_http_status(:too_many_requests)
  end

  it 'throttles login attempts by credential after 10 per minute' do
    11.times do
      post '/usuarios/logar', params: { user: { credentials: 'alvo@example.com', password: 'errada' } }
    end

    expect(response).to have_http_status(:too_many_requests)
  end
end
