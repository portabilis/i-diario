# encoding: utf-8
require 'spec_helper'

RSpec.describe IeducarApi::PostExams, :type => :service do
  let(:url) { "http://test.ieducar.com.br" }
  let(:access_key) { "***REMOVED***" }
  let(:secret_key) { "***REMOVED***" }
  let(:unity_id) { 1 }
  let(:etapa) { 1 }
  let(:turmas) { {  '1234' => { turma_id: '1234' } } }

  subject do
    IeducarApi::PostExams.new(url: url, access_key: access_key, secret_key: secret_key, unity_id: unity_id)
  end

  describe "#send_post" do
    it "returns message" do
      VCR.use_cassette('post_exams') do
        result = subject.send_post(etapa: etapa, turmas: turmas)

        expect(result.keys).to include "msgs"
      end
    end

    it "necessary to inform classrooms" do
      expect {
        subject.send_post(unity_id: 1)
      }.to raise_error("É necessário informar as turmas")
    end

    it "necessary to inform etapa" do
      expect {
        subject.send_post(unity_id: 1, turmas: turmas)
      }.to raise_error("É necessário informar a etapa")
    end
  end
end
