require 'spec_helper'

RSpec.describe AccountsController, :type => :controller do
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
end
