require 'spec_helper'

RSpec.describe EntityConfigurationsController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:entity_configuration) { create(:entity_configuration) }
  let(:user) do
    create(
      :user_with_user_role,
      admin: false
    )
  end

  let(:params) {
    {
      locale: 'pt-BR',
      entity_configuration: {
        entity_name: 'test',
        address_attributes: {
          id: entity_configuration.address.id,
          city: 'test'
        }
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
      expect(get: "configuracoes-da-entidade/editar").to route_to(
        action: "edit",
        controller: "entity_configurations",
        locale: "pt-BR"
      )
    end

    it "routes to update" do
      expect(put: "configuracoes-da-entidade").to route_to(
        action: "update",
        controller: "entity_configurations",
        locale: "pt-BR"
      )
    end
  end

  describe 'PUT #update' do
    it 'does not update and returns error when params are wrong' do
      params[:entity_configuration][:address_attributes][:city] = 0

      put :update, params: params.merge(params)

      expect(response).to have_http_status(302)
    end

    it 'redirects to entity config edit page when params are correct' do
      put :update, params: params
      expect(response).to redirect_to /#{edit_entity_configurations_path}/
    end

    it 'updates value when params are correct' do
      params[:entity_configuration][:entity_name] = 'new name'
      put :update, params: params.merge(params)
      expect(response).to redirect_to /#{edit_entity_configurations_path}/
      expect(EntityConfiguration.current).to have_attributes(entity_name: 'new name')
    end
  end
end
