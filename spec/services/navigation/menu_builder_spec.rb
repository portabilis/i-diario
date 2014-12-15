# encoding: utf-8
require "rails_helper"

describe Navigation::MenuBuilder, :type => :service do
  let :current_user do
    User.new(admin: true)
  end

  subject { described_class.new feature, current_user }

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
        expect(html).to match /<ul>.+Configurações.+<ul><li class="">.+Permissões.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul>.+Permissões.+<li class="">.+Unidades.+<\/li>.+<\/ul>.+<\/ul>/
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
        expect(html).to match /<ul>.+Configurações.+<ul><li class="">.+Permissões.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul>.+Permissões.+<li class="">.+Unidades.+<\/li>.+<\/ul>.+<\/ul>/
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
        expect(html).to match /<ul>.+Configurações.+<ul><li class="">.+Permissões.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul>.+Permissões.+<li class="">.+Unidades.+<\/li>.+<\/ul>.+<\/ul>/
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

    context "when current user has limited access" do
      let(:feature) { "dashboard" }

      let :current_user do
        users(:mary_jane)
      end

      it "returns all permitted ***REMOVED***s" do
        html = subject.build

        expect(html).to_not match /<ul>.+Dashboard.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>/
        expect(html).to_not match /<ul>.+***REMOVED***.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>/
        expect(html).to_not match /<ul>.+***REMOVED***.+<li class="">/
        expect(html).to_not match /<ul>.+***REMOVED***.+<ul>/
        expect(html).to_not match /<ul>.+Configurações.+<ul>.+Permissões.+<li class="">.+Unidades.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to_not match /<ul>.+Configurações.+<ul>.+Configurações gerais.+<li class="">.+API de integração.+<\/li><\/ul>.+<\/ul>/
        expect(html).to_not match /<ul>.+Configurações.+<li class="">.+***REMOVED***.+<\/li>.+<\/ul>/
        expect(html).to_not match /<ul>.+***REMOVED***.+<li class="">/

        expect(html).to match /<ul><li class="current">.+Dashboard.+<\/li>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul>.+Unidades.+<li class="">.+Usuários.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+***REMOVED***.+<ul>.+***REMOVED***.+<\/ul>.+<\/ul>/
      end
    end
  end
end
