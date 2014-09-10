require 'spec_helper'

RSpec.describe UnitiesController, :type => :controller do
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
end
