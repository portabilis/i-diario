# encoding: utf-8
require "rails_helper"

describe Navigation::BreadcrumbsBuilder, :type => :service do
  subject { described_class.new(feature, context) }

  describe "#build" do
    context "when a ***REMOVED*** is informed" do
      let(:feature) { "dashboard" }

      it "returns breadcrumbs with the links begin and ***REMOVED***" do
        expect(subject.build).to eq "<ol class=\"breadcrumb\"><li><a href=\"/\">Início</a></li> <li><a href=\"/\"><i class=\"fa fa-home fa-fw\"></i> Dashboard</a></li></ol>"
      end
   end

    context "when a sub***REMOVED*** is informed" do
      let(:feature) { "roles" }

      it "returns breadcrumbs with the links begin, ***REMOVED*** and sub***REMOVED***" do
        expect(subject.build).to eq "<ol class=\"breadcrumb\"><li><a href=\"/\">Início</a></li> <li><a href=\"#\"><i class=\"fa fa-cog fa-fw\"></i> Configurações</a></li> <li><a href=\"/permissoes\">Permissões</a></li></ol>"
      end
    end

    context "when a invalid ***REMOVED*** is informed" do
      let(:feature) { "invalid ***REMOVED***" }

      it "returns breadcrumbs with link begin" do
        expect(subject.build).to eq "<ol class=\"breadcrumb\"><li><a href=\"/\">Início</a></li></ol>"
      end
    end
  end
end
