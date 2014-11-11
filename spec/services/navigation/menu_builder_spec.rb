# encoding: utf-8
require "rails_helper"

describe Navigation::MenuBuilder, :type => :service do
  subject { described_class.new feature, context }

  describe "#build" do
    context "when informed feature no refers to a ***REMOVED*** or a sub***REMOVED***" do
      let(:feature) { "invalid ***REMOVED***" }

      it "returns all ***REMOVED***s, but no mark nothing ***REMOVED*** or sub***REMOVED*** as current" do
        html = subject.build

        expect(html).to match /<ul><li class="">.+Dashboard.+<\/li>.+<\/ul>/

        expect(html).to match /<ul>.+Dashboard.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>/

        expect(html).to match /<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>/

        expect(html).to match /<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<ul>.+<\/ul>.+<\/li>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul><li class="">.+Tipos de cardápios.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+Tipos de cardápios.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li><\/ul>.+<\/ul>/

        expect(html).to match /<ul>.+***REMOVED***.+<li class="">.+Configurações.+<ul>.+<\/ul>.+<\/li>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul><li class="">.+Perfis de acesso.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul>.+Perfis de acesso.+<li class="">.+Unidades.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul>.+Unidades.+<li class="">.+Configurações gerais.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul>.+Configurações gerais.+<li class="">.+API de integração.+<\/li><\/ul>.+<\/ul>/

        expect(html).to match /<ul>.+Configurações.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>/

        expect(html).to match /<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<ul>.+<\/ul><\/li><\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul><li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li><\/ul>.+<\/ul>/
      end
    end

    context "when informed feature refers to a ***REMOVED***" do
      let(:feature) { "dashboard" }

      it "returns all ***REMOVED***s, but only feature ***REMOVED*** is marked as current" do
        html = subject.build

        expect(html).to match /<ul><li class="current">.+Dashboard.+<\/li>.+<\/ul>/

        expect(html).to match /<ul>.+Dashboard.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>/

        expect(html).to match /<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>/

        expect(html).to match /<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<ul>.+<\/ul>.+<\/li>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul><li class="">.+Tipos de cardápios.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+Tipos de cardápios.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li><\/ul>.+<\/ul>/

        expect(html).to match /<ul>.+***REMOVED***.+<li class="">.+Configurações.+<ul>.+<\/ul>.+<\/li>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul><li class="">.+Perfis de acesso.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul>.+Perfis de acesso.+<li class="">.+Unidades.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul>.+Unidades.+<li class="">.+Configurações gerais.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul>.+Configurações gerais.+<li class="">.+API de integração.+<\/li><\/ul>.+<\/ul>/

        expect(html).to match /<ul>.+Configurações.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>/

        expect(html).to match /<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<ul>.+<\/ul><\/li><\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul><li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li><\/ul>.+<\/ul>/
      end
    end

    context "when informed feature refers to a sub***REMOVED***" do
      let(:feature) { "***REMOVED***s" }

      it "returns all ***REMOVED***s, but only feature sub***REMOVED*** is marked as current and your parent ***REMOVED*** is marked as open" do
        html = subject.build

        expect(html).to match /<ul><li class="">.+Dashboard.+<\/li>.+<\/ul>/

        expect(html).to match /<ul>.+Dashboard.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>/

        expect(html).to match /<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>/

        expect(html).to match /<ul>.+***REMOVED***.+<li class="open">.+***REMOVED***.+<ul style="display: block;">.+<\/ul>.+<\/li>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul style="display: block;"><li class="">.+Tipos de cardápios.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul style="display: block;">.+Tipos de cardápios.+<li class="current">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul style="display: block;">.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li><\/ul>.+<\/ul>/

        expect(html).to match /<ul>.+***REMOVED***.+<li class="">.+Configurações.+<ul>.+<\/ul>.+<\/li>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul><li class="">.+Perfis de acesso.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul>.+Perfis de acesso.+<li class="">.+Unidades.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul>.+Unidades.+<li class="">.+Configurações gerais.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul>.+Configurações gerais.+<li class="">.+API de integração.+<\/li><\/ul>.+<\/ul>/

        expect(html).to match /<ul>.+Configurações.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>/

        expect(html).to match /<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<ul>.+<\/ul><\/li><\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul><li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li><\/ul>.+<\/ul>/
      end
    end
  end
end
