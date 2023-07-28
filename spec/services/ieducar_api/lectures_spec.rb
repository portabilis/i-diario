require 'spec_helper'

RSpec.describe IeducarApi::Lectures, type: :service do
  let(:url) { 'http://test.ieducar.com.br' }
  let(:access_key) { '8IOwGIjiHvbeTklgwo10yVLgwDhhvs' }
  let(:secret_key) { '5y8cfq31oGvFdAlGMCLIeSKdfc8pUC' }
  let(:unity_id) { 1 }

  describe '#fetch' do
    subject do
      IeducarApi::Lectures.new(
        url: url,
        access_key: access_key,
        secret_key: secret_key,
        unity_id: unity_id
      )
    end

    context 'all lectures' do
      it 'returns all lectures' do

        VCR.use_cassette('lectures') do
          result = subject.fetch(escola_id: [30])

          expect(result.keys).to include 'cursos'

          expect(result['cursos'].size).to eq 1
        end
      end
    end
  end
end
