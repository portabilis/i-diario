# encoding: utf-8
require "rails_helper"

describe Navigation::BreadcrumbsBuilder, type: :service do
  subject { described_class.new(feature, context) }

  describe "#build" do
    context "when a menu is informed" do
      let(:feature) { "dashboard" }

      it "returns breadcrumbs with the links begin and menu" do
        expect(subject.build).to eq "<ol class=\"breadcrumb\"><li><a href=\"/\">Início</a></li></ol>"
      end
   end

    context "when a submenu is informed" do
      let(:feature) { "roles" }

      it "returns breadcrumbs with the links begin, menu and submenu" do
        expect(subject.build).to eq "<ol class=\"breadcrumb\"><li><a href=\"/\">Início</a></li> <li><a href=\"#\"><i class=\"fa fa-cog fa-fw\"></i> Configurações</a></li> <li><a href=\"/permissoes\">Permissões</a></li></ol>"
      end
    end

    context "when a invalid menu is informed" do
      let(:feature) { "invalid menu" }

      it "returns breadcrumbs with link begin" do
        expect(subject.build).to eq "<ol class=\"breadcrumb\"><li><a href=\"/\">Início</a></li></ol>"
      end
    end
  end
end
