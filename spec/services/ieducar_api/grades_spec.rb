require 'spec_helper'

RSpec.describe IeducarApi::Grades, type: :service do
  let(:url) { 'http://test.ieducar.com.br' }
  let(:access_key) { '8IOwGIjiHvbeTklgwo10yVLgwDhhvs' }
  let(:secret_key) { '5y8cfq31oGvFdAlGMCLIeSKdfc8pUC' }
  let(:unity_id) { 1 }

  describe '#fetch' do
    subject do
      IeducarApi::Grades.new(
        url: url,
        access_key: access_key,
        secret_key: secret_key,
        unity_id: unity_id
      )
    end

    context 'all grades' do
      it 'returns all grades' do

        VCR.use_cassette('grades') do
          result = subject.fetch

          expect(result.keys).to include 'series'

          expect(result['series'].size).to eq 48
        end
      end
    end
  end
end
