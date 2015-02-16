require 'spec_helper'

RSpec.describe EntityConfigurationsController, type: :controller do
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
end
