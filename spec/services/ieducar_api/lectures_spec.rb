# encoding: utf-8
require 'spec_helper'

RSpec.describe IeducarApi::Lectures, type: :service do
  let(:url) { "http://test.ieducar.com.br" }
  let(:access_key) { "***REMOVED***" }
  let(:secret_key) { "***REMOVED***" }
  let(:unity_id) { 1 }

  describe "#fetch" do
    subject do
      IeducarApi::Lectures.new(url: url, access_key: access_key,
        secret_key: secret_key, unity_id: unity_id)
    end

    context "all lectures" do
      it "necessary to inform escola_id" do
        expect {
          subject.fetch
        }.to raise_error("É necessário informar pelo menos uma escola: escola_id")
      end

      it "returns all lectures" do
        VCR.use_cassette('lectures') do
          result = subject.fetch(escola_id: [121908,  76910])

          expect(result.keys).to include "cursos"

          expect(result["cursos"].size).to eq 3
        end
      end
    end
  end
end
