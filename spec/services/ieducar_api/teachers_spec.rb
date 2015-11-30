# encoding: utf-8
require 'spec_helper'

RSpec.describe IeducarApi::Teachers, :type => :service do
  let(:url) { "http://test.ieducar.com.br" }
  let(:access_key) { "***REMOVED***" }
  let(:secret_key) { "***REMOVED***" }
  let(:unity_id) { 1 }
  let(:ano) { Time.zone.today.year }

  subject do
    IeducarApi::Teachers.new(url: url, access_key: access_key, secret_key: secret_key, unity_id: unity_id)
  end

  describe "#fetch" do
    it "returns all teachers" do
      VCR.use_cassette('all_teachers') do
        result = subject.fetch(ano: ano)

        expect(result.keys).to include "servidores"
      end
    end

    it "necessary to inform ano" do
      expect {
        subject.fetch(unity_id: 1)
      }.to raise_error("É necessário informar o ano")
    end
  end
end
