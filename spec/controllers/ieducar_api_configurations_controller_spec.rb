require 'spec_helper'

RSpec.describe IeducarApiConfigurationsController, :type => :controller do
  context "pt-BR routes" do
    it "routes to edit" do
      expect(get: "api-de-integracao/editar").to route_to(
        action: "edit",
        controller: "ieducar_api_configurations",
        locale: "pt-BR"
      )
    end

    it "routes to update" do
      expect(put: "api-de-integracao").to route_to(
        action: "update",
        controller: "ieducar_api_configurations",
        locale: "pt-BR"
      )
    end
  end
end
