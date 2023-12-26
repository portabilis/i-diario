require 'spec_helper'

RSpec.describe IeducarApi::Classrooms, type: :service do
  let(:url) { 'http://test.ieducar.com.br' }
  let(:access_key) { '8IOwGIjiHvbeTklgwo10yVLgwDhhvs' }
  let(:secret_key) { '5y8cfq31oGvFdAlGMCLIeSKdfc8pUC' }
  let(:unity_id) { 1 }
  let(:year) { Time.zone.today.year }

  subject do
    IeducarApi::Classrooms.new(
      url: url,
      access_key: access_key,
      secret_key: secret_key,
      unity_id: unity_id
    )
  end

  describe '#fetch' do
    it 'returns all classrooms' do

      VCR.use_cassette('all_classrooms') do
        result = subject.fetch(ano: year, escola: unity_id)

        expect(result.keys).to include 'turmas'
      end
    end

    it 'necessary to inform year' do
      expect {
        subject.fetch(escola: unity_id)
      }.to raise_error('É necessário informar o ano')
    end

    it 'necessary to inform school' do
      expect {
        subject.fetch(ano: year)
      }.to raise_error('É necessário informar pelo menos uma escola')
    end
  end
end
