# encoding: utf-8
require 'spec_helper'

RSpec.describe IeducarApi::ExamRules, :type => :service do
  let(:url) { "http://test.ieducar.com.br" }
  let(:access_key) { "***REMOVED***" }
  let(:secret_key) { "***REMOVED***" }
  let(:unity_id) { 1 }
  let(:ano) { Date.today.year }

  subject do
    IeducarApi::ExamRules.new(url: url, access_key: access_key, secret_key: secret_key, unity_id: unity_id)
  end

  describe "#fetch" do
    it "returns all classrooms" do
      VCR.use_cassette('all_exam_rules') do
        result = subject.fetch(ano: ano)

        expect(result.keys).to include "regras"
      end
    end

    it "necessary to inform ano" do
      expect {
        subject.fetch(unity_id: 1)
      }.to raise_error("É necessário informar o ano")
    end
  end
end
