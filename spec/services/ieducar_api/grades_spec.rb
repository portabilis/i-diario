# encoding: utf-8
require 'spec_helper'

RSpec.describe IeducarApi::Grades, type: :service do
  let(:url) { "http://test.ieducar.com.br" }
  let(:access_key) { "***REMOVED***" }
  let(:secret_key) { "***REMOVED***" }
  let(:unity_id) { 1 }

  describe "#fetch" do
    subject do
      IeducarApi::Grades.new(url: url, access_key: access_key,
        secret_key: secret_key, unity_id: unity_id)
    end

    context "all grades" do
      it "is necessary to inform escola_id" do
        expect {
          subject.fetch
        }.to raise_error("É necessário informar pelo menos uma escola: escola_id")
      end

      it "is necessary to inform curso_id" do
        expect {
          subject.fetch(escola_id: [1])
        }.to raise_error("É necessário informar pelo menos um curso: curso_id")
      end

      it "returns all grades" do
        VCR.use_cassette('grades') do
          result = subject.fetch(escola_id: [121908,  76910], curso_id: [1, 4])

          expect(result.keys).to include "series"

          expect(result["series"].size).to eq 10
        end
      end
    end
  end
end
