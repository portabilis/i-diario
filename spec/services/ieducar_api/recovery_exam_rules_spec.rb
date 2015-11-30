# encoding: utf-8
require 'spec_helper'

RSpec.describe IeducarApi::RecoveryExamRules, :type => :service do
  let(:url) { "http://test.ieducar.com.br" }
  let(:access_key) { "***REMOVED***" }
  let(:secret_key) { "***REMOVED***" }
  let(:unity_id) { 1 }
  let(:ano) { Time.zone.today.year }

  subject do
    IeducarApi::RecoveryExamRules.new(url: url, access_key: access_key, secret_key: secret_key, unity_id: unity_id)
  end

  describe "#fetch" do
    it "returns all recovery exam rules" do
      VCR.use_cassette('all_recovery_exam_rules') do
        result = subject.fetch

        expect(result.keys).to include "regras-recuperacao"
      end
    end
  end
end
