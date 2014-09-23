# encoding: utf-8
require 'spec_helper'

RSpec.describe IeducarApi::StudentRegistrations, :type => :service do
  let(:url) { "http://test.ieducar.com.br" }
  let(:access_key) { "***REMOVED***" }
  let(:secret_key) { "***REMOVED***" }
  let(:unity_id) { 1 }

  subject do
    IeducarApi::StudentRegistrations.new(url: url, access_key: access_key, secret_key: secret_key, unity_id: unity_id)
  end

  describe "#fetch" do
    it "returns student registrations" do
      VCR.use_cassette('student_registrations') do
        result = subject.fetch(aluno_id: [8930, 7588])

        expect(result.keys).to include "matriculas"

        expect(result["matriculas"].size).to eq 1
      end
    end

    it "necessary to inform aluno_id" do
      expect {
        subject.fetch
      }.to raise_error("É necessário informar os códigos dos alunos: aluno_id")
    end
  end
end
