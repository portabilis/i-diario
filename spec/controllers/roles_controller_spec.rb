require 'spec_helper'

RSpec.describe RolesController, :type => :controller do
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
end
