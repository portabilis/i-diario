require 'spec_helper'

RSpec.describe RolesController, :type => :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) { create(:user_with_user_role) }
  let(:user_role) { user.user_roles.first }
  let(:unity) { create(:unity) }
  let(:role_permission) { create(:role_permission, role: user_role.role) }

  let(:params) {
    {
      locale: 'pt-BR',
      role: {
        name: 'test',
        access_level: 'administrator'
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
    it "routes to index" do
      expect(get: "permissoes").to route_to(
        controller: "roles",
        action: "index",
        locale: "pt-BR"
      )
    end

    it "routes to show" do
      expect(get: "permissoes/1").to route_to(
        controller: "roles",
        action: "show",
        id: "1",
        locale: "pt-BR"
      )
    end

    it "routes to new" do
      expect(get: "permissoes/novo").to route_to(
        controller: "roles",
        action: "new",
        locale: "pt-BR"
      )
    end

    it "routes to create" do
      expect(post: "permissoes").to route_to(
        controller: "roles",
        action: "create",
        locale: "pt-BR"
      )
    end

    it "routes to edit" do
      expect(get: "permissoes/1/editar").to route_to(
        action: "edit",
        controller: "roles",
        locale: "pt-BR",
        id: "1"
      )
    end

    it "routes to update" do
      expect(put: "permissoes/1").to route_to(
        action: "update",
        controller: "roles",
        locale: "pt-BR",
        id: "1"
      )
    end
  end

  describe 'POST #create' do
    context 'without success' do
      it 'fails to create and renders the new template' do
        post :create, params: params.merge(role: { permissions_attributes: nil })
        expect(response).to render_template(:new)
      end
    end

    context 'with success' do
      it 'creates and redirects to daily frequency edit page' do
        post :create, params: params
        expect(response).to redirect_to /#{roles_path}/
      end
    end
  end

  describe 'PUT #update' do
    it 'updates when params are correct' do
      put :update, params: params.merge(id: user_role.role.id)
      expect(Role.find(user_role.role.id)).to have_attributes(name: 'test')
    end

    it 'does not update and returns error when params are wrong' do
      put :update, params: params.merge(id: user_role.role.id, role: { permissions_attributes: { feature: 'roles' } })
      expect(response).to have_http_status(302)
    end

  end
end
