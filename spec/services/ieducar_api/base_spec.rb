# encoding: utf-8
require 'spec_helper'

RSpec.describe IeducarApi::Base, :type => :service do
  let(:url) { "http://test.ieducar.com.br" }
  let(:access_key) { "***REMOVED***" }
  let(:secret_key) { "***REMOVED***" }
  let(:unity_id) { 1 }

  context "ensure obligatory params" do
    it "requires url" do
      expect {
        IeducarApi::Base.new({})
      }.to raise_error("É necessário informar a url de acesso: url")
    end

    it "requires access_key" do
      expect {
        IeducarApi::Base.new(url: url)
      }.to raise_error("É necessário informar a chave de acesso: access_key")
    end

    it "requires secret_key" do
      expect {
        IeducarApi::Base.new(url: url, access_key: access_key)
      }.to raise_error("É necessário informar a chave secreta: secret_key")
    end

    it "requires unity_id" do
      expect {
        IeducarApi::Base.new(url: url, access_key: access_key, secret_key: secret_key)
      }.to raise_error("É necessário informar o id da unidade: unity_id")
    end
  end

  describe "#fetch" do
    subject do
      IeducarApi::Base.new(url: url, access_key: access_key, secret_key: secret_key, unity_id: unity_id)
    end

    let(:path) { "module/Api/Aluno" }
    let(:resource) { "todos-alunos" }

    context "ensure obligatory options" do
      it "requires path" do
        expect {
          subject.fetch
        }.to raise_error("É necessário informar o caminho de acesso: path")
      end

      it "requires resource" do
        expect {
          subject.fetch(path: path)
        }.to raise_error("É necessário informar o recurso de acesso: resource")
      end
    end

    context "all students" do
      it "returns all students" do
        VCR.use_cassette('all_students') do
          result = subject.fetch(path: path, resource: resource)

          expect(result.keys).to include "alunos"

          expect(result["alunos"].size).to eq 100
        end
      end
    end
  end

  context "with wrong options" do
    let(:path) { "module/Api/Aluno" }
    let(:resource) { "todos-alunos" }

    context "invalid keys" do
      it "returns an error when providing an invalid access_key" do
        subject = IeducarApi::Base.new(url: url, access_key: "invalid", secret_key: secret_key, unity_id: unity_id)

        VCR.use_cassette("invalid_access_key") do
          expect {
            subject.fetch(path: path, resource: resource)
          }.to raise_error("Chave de acesso inválida!")
        end
      end
    end

    it "returns an error when providing an invalid url" do
      subject = IeducarApi::Base.new(url: "http://botucat.ieduca.com.br", access_key: access_key, secret_key: secret_key, unity_id: unity_id)

      VCR.use_cassette("wrong_endpoint_url") do
        expect {
          subject.fetch(path: path, resource: resource)
        }.to raise_error("URL do i-Educar informada não é válida.")
      end
    end

    it "returns an error when providing an invalid client url" do
      subject = IeducarApi::Base.new(url: "http://botucat.ieducar.com.br", access_key: access_key, secret_key: secret_key, unity_id: unity_id)

      VCR.use_cassette("wrong_client_url") do
        expect {
          subject.fetch(path: path, resource: resource)
        }.to raise_error("URL do i-Educar informada não é válida.")
      end
    end

    it "returns an error when providing an invalid resource" do
      subject = IeducarApi::Base.new(url: url, access_key: access_key, secret_key: secret_key, unity_id: unity_id)

      VCR.use_cassette("wrong_resource") do
        expect {
          subject.fetch(path: path, resource: "errado")
        }.to raise_error("Operação 'get' não implementada para o recurso 'errado'")
      end
    end
  end
end
