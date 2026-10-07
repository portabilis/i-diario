require 'rails_helper'

# CVE-2025-9109 / GHSA (VulnDB-320431)
# O endpoint de recuperação de senha revelava se um e-mail existia: e-mail cadastrado redirecionava
# com mensagem de sucesso; e-mail inexistente re-renderizava o formulário com "não encontrado".
# Com config.paranoid a resposta é idêntica nos dois casos, impedindo enumeração de usuários.
RSpec.describe Users::PasswordsController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  before do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  let!(:existing_user) { create(:user, email: 'cadastrado@portabilis.com.br') }

  def request_reset(email)
    post :create, params: { locale: 'pt-BR', user: { email: email } }
  end

  it 'responds the same way for a registered and an unregistered e-mail' do
    request_reset('cadastrado@portabilis.com.br')
    registered = { status: response.status, location: response.location, notice: flash[:notice], alert: flash[:alert] }

    request_reset('nao-existe-xyz@portabilis.com.br')
    unregistered = { status: response.status, location: response.location, notice: flash[:notice], alert: flash[:alert] }

    expect(unregistered).to eq(registered)
  end

  it 'redirects instead of re-rendering the form for an unregistered e-mail' do
    request_reset('nao-existe-xyz@portabilis.com.br')

    expect(response).to have_http_status(:redirect)
    expect(flash[:notice]).to be_present
  end

  it 'does not expose a "not found" error for an unregistered e-mail' do
    request_reset('nao-existe-xyz@portabilis.com.br')

    expect(assigns(:user)&.errors&.full_messages.to_a.join).not_to match(/não encontrado/i)
  end
end
