require 'spec_helper'

RSpec.describe UsersController, :type => :controller do
  context "pt-BR routes" do
    it "routes to index" do
      expect(get: "usuarios").to route_to(
        controller: "users",
        action: "index",
        locale: "pt-BR"
      )
    end

    it "routes to edit" do
      expect(get: "usuarios/1/editar").to route_to(
        action: "edit",
        controller: "users",
        locale: "pt-BR",
        id: "1"
      )
    end

    it "routes to update" do
      expect(put: "usuarios/1").to route_to(
        action: "update",
        controller: "users",
        locale: "pt-BR",
        id: "1"
      )
    end
  end
end
