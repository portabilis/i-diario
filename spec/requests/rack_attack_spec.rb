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

  def request_password_reset(path, times)
    times.times { post path, params: { user: { email: 'atacante@example.com' } } }
  end

  def attempt_login(path, times, credentials: 'alvo@example.com')
    times.times { post path, params: { user: { credentials: credentials, password: 'errada' } } }
  end

  context 'with password reset' do
    %w[/usuarios/senha /users/password /usuarios/senha.html].each do |path|
      it "throttles #{path} by IP after 5 per minute" do
        request_password_reset(path, 6)

        expect(response).to have_http_status(:too_many_requests)
      end
    end

    it 'does not throttle under the limit' do
      request_password_reset('/usuarios/senha', 5)

      expect(response).not_to have_http_status(:too_many_requests)
    end

    it 'answers the throttled request with a page in Portuguese' do
      request_password_reset('/usuarios/senha', 6)

      expect(response.content_type).to eq('text/html')
      expect(response.body).to include(I18n.t('rack_attack.throttled'))
      expect(response.headers['Retry-After'].to_i).to be_between(1, 60)
    end
  end

  context 'with login' do
    %w[/usuarios/logar /users/sign_in /usuarios/logar.html].each do |path|
      it "throttles #{path} by credential after 10 per minute" do
        attempt_login(path, 11)

        expect(response).to have_http_status(:too_many_requests)
      end
    end

    it 'does not throttle under the limit' do
      attempt_login('/usuarios/logar', 10)

      expect(response).not_to have_http_status(:too_many_requests)
    end

    it 'counts credentials regardless of case and surrounding spaces' do
      attempt_login('/usuarios/logar', 10, credentials: 'Alvo@Example.com ')
      attempt_login('/usuarios/logar', 1)

      expect(response).to have_http_status(:too_many_requests)
    end

    it 'does not share the counter between credentials' do
      attempt_login('/usuarios/logar', 10)
      attempt_login('/usuarios/logar', 1, credentials: 'outro@example.com')

      expect(response).not_to have_http_status(:too_many_requests)
    end
  end

  context 'with login in more than one entity' do
    it 'does not share the counter between entities with the same credential' do
      host! 'rede-a.host'
      attempt_login('/usuarios/logar', 10, credentials: 'admin')
      host! 'rede-b.host'
      attempt_login('/usuarios/logar', 1, credentials: 'admin')

      expect(response).not_to have_http_status(:too_many_requests)
    end
  end
end
