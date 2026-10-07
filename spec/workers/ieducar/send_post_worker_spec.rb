require 'rails_helper'

RSpec.describe Ieducar::SendPostWorker, type: :worker do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  # Esta é a única linha do sistema que decide com qual das duas APIs do i-Educar um envio de
  # faltas ou de notas conversa. O payload achatado vai para a API v2; jobs com o payload legado
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

    context 'when the payload is a flat score' do
      let(:params) do
        { 'etapa' => 1, 'turma_id' => '4502', 'aluno_id' => '1234', 'componente_id' => '9', 'nota' => '7.5' }
      end

      [
        ApiPostingTypes::NUMERICAL_EXAM,
        ApiPostingTypes::CONCEPTUAL_EXAM,
        ApiPostingTypes::SCHOOL_TERM_RECOVERY,
        ApiPostingTypes::FINAL_RECOVERY
      ].each do |score_type|
        context "for #{score_type}" do
          let(:post_type) { score_type }

          it 'uses the v2 scores client, built from the api configuration record' do
            expect(IeducarApi::PostScores).to receive(:new)
              .with(posting.ieducar_api_configuration)
              .and_call_original

            expect(subject.send(:api, posting, params)).to be_a(IeducarApi::PostScores)
          end
        end
      end
    end

    context 'when a legacy score payload is still in the queue' do
      let(:post_type) { ApiPostingTypes::NUMERICAL_EXAM }
      let(:params) { { 'etapa' => 1, 'resource' => 'notas', 'notas' => { '4502' => {} } } }

      it 'stays on the legacy client' do
        expect(subject.send(:api, posting, params)).to be_a(IeducarApi::PostExams)
      end
    end

    # A recuperação final legada não leva `resource`: o que a separa da v2 é não ter `turma_id`.
    context 'when a legacy final recovery payload is still in the queue' do
      let(:post_type) { ApiPostingTypes::FINAL_RECOVERY }
      let(:params) { { 'notas' => { '4502' => { '1234' => { '9' => { 'nota' => 6 } } } } } }

      it 'stays on the legacy client' do
        expect(subject.send(:api, posting, params)).to be_a(IeducarApi::FinalRecoveries)
      end
    end

    context 'with descriptive exams' do
      let(:post_type) { ApiPostingTypes::DESCRIPTIVE_EXAM }
      let(:params) { { 'etapa' => 1, 'resource' => 'pareceres-por-etapa-e-componente', 'pareceres' => {} } }

      it 'stays on the legacy client' do
        expect(subject.send(:api, posting, params)).to be_a(IeducarApi::PostDescriptiveExams)
      end
    end
  end
end
