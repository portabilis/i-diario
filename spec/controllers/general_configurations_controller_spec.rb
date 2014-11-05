require 'spec_helper'

RSpec.describe GeneralConfigurationsController, type: :controller do
  context "pt-BR routes" do
    it "routes to edit" do
      expect(get: "configuracoes-gerais/editar").to route_to(
        action: "edit",
        controller: "general_configurations",
        locale: "pt-BR"
      )
    end

    it "routes to update" do
      expect(put: "configuracoes-gerais").to route_to(
        action: "update",
        controller: "general_configurations",
        locale: "pt-BR"
      )
    end
  end
end
