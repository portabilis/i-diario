require 'spec_helper'

RSpec.describe IeducarApi::Students, type: :service do
  let(:url) { 'http://test.ieducar.com.br' }
  let(:access_key) { '2Me9freQ6gpneyCOlWRcVSx2huwa3X' }
  let(:secret_key) { '7AWURgchB84ZeY7q8voyIuJeATOsny' }
  let(:unity_id) { 2 }
  let(:resource) { 'todos-alunos' }

  subject do
    IeducarApi::Students.new(
      url: url,
      access_key: access_key,
      secret_key: secret_key,
      unity_id: unity_id
    )
  end

  describe '#fetch' do
    it 'returns all students' do
      VCR.use_cassette('all_students') do
        result = subject.fetch(escola: unity_id, resource: resource)

        expect(result.keys).to include 'alunos'

        expect(result['alunos'].size).to eq(430)
      end
    end
  end
end
