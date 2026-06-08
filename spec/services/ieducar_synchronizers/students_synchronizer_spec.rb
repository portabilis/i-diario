require 'rails_helper'

RSpec.describe StudentsSynchronizer do
  let(:synchronization) { create(:ieducar_api_synchronization) }

  let(:api_response) do
    {
      'alunos' => [
        {
          'aluno_id' => 99999,
          'nome_aluno' => 'ALUNO TESTE',
          'nome_social' => nil,
          'foto_aluno' => nil,
          'data_nascimento' => '2010-05-15',
          'deleted_at' => nil
        }
      ]
    }
  end

  let(:synchronizer) do
    StudentsSynchronizer.new(
      synchronization: synchronization,
      worker_batch: nil,
      worker_state: nil,
      entity_id: nil,
      year: 2026,
      unity_api_code: nil,
      current_years: [2026]
    )
  end

  before do
    allow_any_instance_of(IeducarApi::Students)
      .to receive(:fetch).and_return(api_response)

    allow(GeneralConfiguration).to receive_message_chain(:current, :create_users_for_students_when_synchronize)
      .and_return(false)
  end

  describe 'race condition handling' do
    # Cenário real: dois workers de unidades diferentes sincronizando em paralelo
    # recebem o mesmo aluno da API. O primeiro worker cria o registro,
    # e o segundo falha com UniqueViolation ao tentar inserir o mesmo api_code.
    it 'handles race condition when another process inserts the same student between SELECT and INSERT' do
      call_count = 0

      allow(Student).to receive(:with_discarded).and_return(Student)

      allow(Student).to receive(:find_or_initialize_by)
        .with(api_code: 99999)
        .and_wrap_original do |method, *args|
          call_count += 1
          result = method.call(*args)

          # Na primeira chamada, simula outro worker criando o registro
          if call_count == 1 && result.new_record?
            Student.create!(
              api_code: 99999,
              name: 'ALUNO TESTE',
              api: true,
              birth_date: '2010-05-15'
            )
          end

          result
        end

      expect { synchronizer.synchronize! }.not_to raise_error

      expect(Student.where(api_code: 99999).count).to eq(1)

      # O retry deve ter sido executado (2 chamadas ao find_or_initialize_by)
      expect(call_count).to eq(2)
    end
  end

  describe '#synchronize!' do
    it 'creates student normally when no race condition occurs' do
      allow(Student).to receive(:with_discarded).and_return(Student)

      expect { synchronizer.synchronize! }.not_to raise_error

      student = Student.find_by(api_code: 99999)
      expect(student).to be_present
      expect(student.name).to eq('ALUNO TESTE')
      expect(student.birth_date.to_s).to eq('2010-05-15')
    end

    it 'updates existing student without error' do
      existing = create(:student, api_code: 99999, name: 'NOME ANTIGO')

      allow(Student).to receive(:with_discarded).and_return(Student)

      expect { synchronizer.synchronize! }.not_to raise_error

      expect(Student.where(api_code: 99999).count).to eq(1)
      expect(existing.reload.name).to eq('ALUNO TESTE')
    end
  end
end
