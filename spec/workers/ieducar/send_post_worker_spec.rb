require 'rails_helper'

RSpec.describe Ieducar::SendPostWorker, type: :worker do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  # Esta é a única linha do sistema que decide para qual endpoint da API v2 do i-Educar um envio de
  # faltas, notas ou pareceres vai: o tipo do envio e os campos do payload escolhem o cliente.
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

    # A recuperação final legada não leva `resource`: o que a separa da v2 é não ter `turma_id`.
    context 'when the payload is a flat descriptive exam' do
      let(:post_type) { ApiPostingTypes::DESCRIPTIVE_EXAM }

      # O tipo de parecer sai dos campos: os anuais não têm etapa, e os gerais não têm componente.
      {
        { 'etapa' => 1 } => IeducarApi::PostOpinionsByStep,
        { 'etapa' => 1, 'componente_id' => '9' } => IeducarApi::PostOpinionsByStepAndDiscipline,
        {} => IeducarApi::PostOpinionsByYear,
        { 'componente_id' => '9' } => IeducarApi::PostOpinionsByYearAndDiscipline
      }.each do |fields, api_class|
        it "uses #{api_class.name.demodulize} for #{fields.keys.inspect}" do
          params = { 'turma_id' => '4502', 'aluno_id' => '1234', 'parecer' => 'Texto' }.merge(fields)

          expect(subject.send(:api, posting, params)).to be_a(api_class)
        end
      end
    end

  end
end
