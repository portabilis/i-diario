require 'spec_helper'

RSpec.describe UnitiesController, :type => :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) { create(:user_with_user_role, admin: false) }

  let(:params) {
    {
      locale: 'pt-BR',
      unity: attributes_for(:unity)
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
      expect(get: "unidades").to route_to(
        controller: "unities",
        action: "index",
        locale: "pt-BR"
      )
    end

    it "routes to show" do
      expect(get: "unidades/1").to route_to(
        controller: "unities",
        action: "show",
        id: "1",
        locale: "pt-BR"
      )
    end

    it "routes to new" do
      expect(get: "unidades/novo").to route_to(
        controller: "unities",
        action: "new",
        locale: "pt-BR"
      )
    end

    it "routes to create" do
      expect(post: "unidades").to route_to(
        controller: "unities",
        action: "create",
        locale: "pt-BR"
      )
    end

    it "routes to edit" do
      expect(get: "unidades/1/editar").to route_to(
        action: "edit",
        controller: "unities",
        locale: "pt-BR",
        id: "1"
      )
    end

    it "routes to update" do
      expect(put: "unidades/1").to route_to(
        action: "update",
        controller: "unities",
        locale: "pt-BR",
        id: "1"
      )
    end
  end

  describe 'GET #index' do
    let(:unities) { create_list(:unity, 2) }

    it 'lists all unities when params are correct' do
      get :index, params: { locale: 'pt-BR' }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #show' do
    let(:unities) { create_list(:unity, 2) }

    it 'list unity when params are correct' do
      get :show, params: { locale: 'pt-BR', id: unities.first.id }
      expect(response.body).to include(unities.first.id.to_s)
    end
  end

  describe 'POST #create' do
    it 'fails to create and renders the new template' do
      params[:unity] = { name: nil }
      post :create, params: params.merge(params)
      expect(response).to render_template(:new)
    end

    it 'creates and redirects to daily frequency edit page' do
      post :create, params: params
      expect(response).to redirect_to(unities_path)
    end
  end

  describe 'PUT #update' do
    let(:unity) { create(:unity) }

    it 'does not update and returns error when params are wrong' do
      params[:unity] = { name: nil }
      params[:id] = unity.id
      put :update, params: params.merge(params)
      expect(response).to render_template(:edit)
    end

    it 'updates when params are correct' do
      params[:id] = unity.id
      params[:unity] = { name: 'new name' }
      put :update, params: params.merge(params)
      expect(Unity.find(unity.id)).to have_attributes(name: 'new name')
      expect(response).to redirect_to(unities_path)
    end
  end

  describe 'DELETE #destroy' do
    it 'discards when unity is not active' do
      unity = create(:unity, active: false)
      params[:id] = unity.id
      delete :destroy, params: params.merge(params)
      expect(Unity.with_discarded.find(unity.id).discarded_at).not_to be(nil)
      expect(response).to redirect_to(unities_path)
    end

    it 'destroys when unity is active' do
      unity = create(:unity, active: true)
      params[:id] = unity.id
      expect {
        delete :destroy, params: params.merge(params)
      }.to change(Unity, :count).by(-1)
    end

    it 'does not destroy when params are wrong' do
      unity = create(:unity, active: true)
      params[:id] = 0
      delete :destroy, params: params.merge(params)
      expect {
        delete :destroy, params: params.merge(params)
      }.not_to change(Unity, :count)
    end
  end

  describe 'DELETE #destroy_batch' do
    let(:unities) { create_list(:unity, 2) }

    it 'destroys when params are correct' do
      params[:ids] = unities.map(&:id)
      expect {
        delete :destroy_batch, params: params.merge(params)
      }.to change(Unity, :count).by(-2)
    end

    it 'does not destroy when params are wrong' do
      params[:ids] = 0
      expect {
        delete :destroy_batch, params: params.merge(params)
      }.not_to change(Unity, :count)
    end
  end
end
