require 'rails_helper'

RSpec.describe ExamRulesSynchronizer do
  describe 'race condition handling' do
    let(:rounding_table) { create(:rounding_table, api_code: '1') }

    # Simula a resposta da API
    let(:api_response) do
      {
        'regras' => [
          {
            'id' => 999,
            'tipo_nota' => 1,
            'tipo_presenca' => 1,
            'tipo_recuperacao' => 0,
            'media_recuperacao_paralela' => nil,
            'parecer_descritivo' => 2,  # OpinionTypes::BY_STEP_AND_DISCIPLINE
            'nota_maxima_exame' => 10,
            'tabela_arredondamento_id' => '1',
            'tabela_arredondamento_id_conceitual' => nil,
            'tipo_calculo_recuperacao_paralela' => 1,
            'regra_diferenciada_id' => nil
          }
        ]
      }
    end

    it 'handles race condition when record is created by another process' do
      # Simula o cenário onde outro processo cria o registro entre find e save
      call_count = 0

      allow(ExamRule).to receive(:find_or_initialize_by).and_wrap_original do |method, *args|
        call_count += 1
        result = method.call(*args)

        # Na primeira chamada, simula outro processo criando o registro
        if call_count == 1 && result.new_record?
          ExamRule.create!(
            api_code: '999',
            score_type: 1,
            frequency_type: 1,
            recovery_type: 0,
            opinion_type: 2,  # OpinionTypes::BY_STEP_AND_DISCIPLINE
            final_recovery_maximum_score: 10
          )
        end

        result
      end

      synchronizer = ExamRulesSynchronizer.new(
        synchronization: create(:ieducar_api_synchronization),
        worker_batch: nil,
        worker_state: nil,
        entity_id: nil,
        year: 2025,
        unity_api_code: nil,
        current_years: [2025]
      )

      # Permite que o synchronizer chame a API mockada
      allow_any_instance_of(IeducarApi::ExamRules).to receive(:fetch).and_return(api_response)

      # Não deve lançar exceção - o retry deve funcionar
      expect { synchronizer.synchronize! }.not_to raise_error

      # Deve existir apenas 1 registro (não duplicado)
      expect(ExamRule.where(api_code: '999').count).to eq(1)
    end

    it 'creates exam rule normally when no race condition' do
      synchronizer = ExamRulesSynchronizer.new(
        synchronization: create(:ieducar_api_synchronization),
        worker_batch: nil,
        worker_state: nil,
        entity_id: nil,
        year: 2025,
        unity_api_code: nil,
        current_years: [2025]
      )

      allow_any_instance_of(IeducarApi::ExamRules).to receive(:fetch).and_return(api_response)

      expect { synchronizer.synchronize! }.not_to raise_error
      expect(ExamRule.where(api_code: '999').count).to eq(1)
    end

    it 'updates existing exam rule' do
      # Cria registro existente
      existing = create(:exam_rule, api_code: '999', score_type: 0)

      synchronizer = ExamRulesSynchronizer.new(
        synchronization: create(:ieducar_api_synchronization),
        worker_batch: nil,
        worker_state: nil,
        entity_id: nil,
        year: 2025,
        unity_api_code: nil,
        current_years: [2025]
      )

      allow_any_instance_of(IeducarApi::ExamRules).to receive(:fetch).and_return(api_response)

      expect { synchronizer.synchronize! }.not_to raise_error

      # Deve ter atualizado, não criado novo
      expect(ExamRule.where(api_code: '999').count).to eq(1)
      expect(existing.reload.score_type).to eq('1')
    end

    it 'raises error after MAX_RETRIES attempts' do
      # Simula race condition persistente que sempre falha
      allow(ExamRule).to receive(:find_or_initialize_by).and_wrap_original do |method, *args|
        result = method.call(*args)

        # Sempre cria conflito se for novo registro
        if result.new_record?
          ExamRule.create!(
            api_code: '999',
            score_type: 1,
            frequency_type: 1,
            recovery_type: 0,
            opinion_type: 2,
            final_recovery_maximum_score: 10
          ) unless ExamRule.exists?(api_code: '999')
        end

        # Força retornar sempre um novo registro para simular race persistente
        ExamRule.new(api_code: '999')
      end

      synchronizer = ExamRulesSynchronizer.new(
        synchronization: create(:ieducar_api_synchronization),
        worker_batch: nil,
        worker_state: nil,
        entity_id: nil,
        year: 2025,
        unity_api_code: nil,
        current_years: [2025]
      )

      allow_any_instance_of(IeducarApi::ExamRules).to receive(:fetch).and_return(api_response)

      # Deve lançar erro após MAX_RETRIES tentativas
      expect { synchronizer.synchronize! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
