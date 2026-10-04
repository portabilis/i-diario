require 'rails_helper'

RSpec.describe Ieducar::SendPostWorker, type: :worker do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  # Esta é a única linha do sistema que decide com qual das duas APIs do i-Educar um envio de
  # faltas conversa. Faltas gerais e por componente vão para a API v2; jobs com o payload legado
  # que ainda estejam na fila durante um deploy continuam na legada.
  describe '#api' do
    let(:posting) { create(:ieducar_api_exam_posting, post_type: post_type) }

    context 'when the payload is a general absence' do
      let(:post_type) { ApiPostingTypes::ABSENCE }
      # Chaves em String: é assim que o payload volta do round-trip JSON do Sidekiq.
      let(:params) do
        { 'etapa' => 1, 'turma_id' => '4502', 'aluno_id' => '1234', 'faltas' => 3 }
      end

      it 'uses the v2 client, built from the api configuration record' do
        expect(IeducarApi::PostGeneralAbsences).to receive(:new)
          .with(posting.ieducar_api_configuration)
          .and_call_original

        expect(subject.send(:api, posting, params)).to be_a(IeducarApi::PostGeneralAbsences)
      end
    end

    context 'when the payload is a per discipline absence' do
      let(:post_type) { ApiPostingTypes::ABSENCE }
      let(:params) do
        { 'etapa' => 1, 'turma_id' => '4502', 'aluno_id' => '1234', 'componente_id' => '9', 'faltas' => 3 }
      end

      it 'uses the v2 discipline client, built from the api configuration record' do
        expect(IeducarApi::PostDisciplineAbsences).to receive(:new)
          .with(posting.ieducar_api_configuration)
          .and_call_original

        expect(subject.send(:api, posting, params)).to be_a(IeducarApi::PostDisciplineAbsences)
      end
    end

    context 'when a legacy per discipline payload is still in the queue' do
      let(:post_type) { ApiPostingTypes::ABSENCE }
      let(:params) do
        {
          'etapa' => 1,
          'resource' => 'faltas-por-componente',
          'faltas' => { '4502' => { '1234' => { '9' => { 'valor' => 3 } } } }
        }
      end

      it 'stays on the legacy client, built from the to_api hash' do
        expect(IeducarApi::PostAbsences).to receive(:new).with(posting.to_api).and_call_original

        expect(subject.send(:api, posting, params)).to be_a(IeducarApi::PostAbsences)
      end
    end

    context 'when a legacy general payload is still in the queue' do
      let(:post_type) { ApiPostingTypes::ABSENCE }
      let(:params) do
        {
          'etapa' => 1,
          'resource' => 'faltas-geral',
          'faltas' => { '4502' => { '1234' => { 'valor' => 3 } } }
        }
      end

      it 'stays on the legacy client so in-flight jobs keep working' do
        expect(subject.send(:api, posting, params)).to be_a(IeducarApi::PostAbsences)
      end
    end

    context 'with other posting types' do
      let(:post_type) { ApiPostingTypes::NUMERICAL_EXAM }
      let(:params) { { 'etapa' => 1, 'resource' => 'notas', 'notas' => {} } }

      it 'is not affected by the absence routing' do
        expect(subject.send(:api, posting, params)).to be_a(IeducarApi::PostExams)
      end
    end
  end
end
