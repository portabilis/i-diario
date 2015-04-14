# encoding: utf-8
require 'spec_helper'

RSpec.describe IeducarApi::Disciplines, :type => :service do
  let(:url) { "http://test.ieducar.com.br" }
  let(:access_key) { "***REMOVED***" }
  let(:secret_key) { "***REMOVED***" }
  let(:unity_id) { 1 }

  subject do
    IeducarApi::Disciplines.new(url: url, access_key: access_key, secret_key: secret_key, unity_id: unity_id)
  end

  describe "#fetch" do
    it "returns all disciplines" do
      VCR.use_cassette('all_disciplines') do
        result = subject.fetch

        expect(result.keys).to include "disciplinas"
      end
    end
  end
end
