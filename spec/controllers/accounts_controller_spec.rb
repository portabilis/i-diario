require 'spec_helper'

RSpec.describe AccountsController, :type => :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) { create(:user, :with_user_role_administrator) }

  let(:params) {
    {
      locale: 'pt-BR',
      user: {
        email: user.email,
        first_name: 'test'
      }
    }
  }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  before do
    sign_in(user)
    allow(controller).to receive(:authorize).and_return(true)
    request.env['REQUEST_PATH'] = ''
  end

  context "pt-BR routes" do
    it "routes to edit" do
      expect(get: "conta/editar").to route_to(
        action: "edit",
        controller: "accounts",
        locale: "pt-BR"
      )
    end

    it "routes to update" do
      expect(put: "conta").to route_to(
        action: "update",
        controller: "accounts",
        locale: "pt-BR"
      )
    end
  end

  describe 'PUT #update' do
    it 'does not update and returns error when params are wrong' do
      params[:user] = nil
      put :update, params: params.merge(params)
      expect(response).to have_http_status(302)
    end

    it 'redirects to account edit page when password is weak' do
      params[:user][:password] = 'weak'
      put :update, params: params.merge(params)
      expect(response).to render_template(:edit)
    end

    it 'updates when password is strong' do
      params[:user][:password] = '!Test123'
      put :update, params: params.merge(params)
      expect(response).to have_http_status(:ok)
      expect(response.headers['Location']).to eq('/conta/editar')
    end

    it 'redirects to account edit page when params are correct' do
      put :update, params: params
      expect(response.headers['Location']).to eq('/conta/editar')
    end

    it 'updates value when params are correct' do
      params[:user][:first_name] = 'new name'
      put :update, params: params.merge(params)
      expect(response.headers['Location']).to eq('/conta/editar')
      expect(user).to have_attributes(first_name: 'new name')
    end
  end
end
