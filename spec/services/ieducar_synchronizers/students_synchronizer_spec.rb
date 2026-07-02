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
      collisions = 0

      allow(Student).to receive(:with_discarded).and_return(Student)

      # Simula a corrida: o preload não encontrou o aluno, então tentamos criar
      # via Student.new + save!. No primeiro INSERT, outro worker já inseriu o
      # mesmo api_code, fazendo o banco levantar RecordNotUnique.
      allow_any_instance_of(Student).to receive(:save!).and_wrap_original do |original|
        # O primeiro save! é o INSERT do registro novo; nele simulamos o outro
        # worker comitando antes e o banco levantando RecordNotUnique.
        if collisions.zero?
          collisions += 1
          Student.create!(api_code: 99999, name: 'CRIADO POR OUTRO WORKER', api: true, birth_date: '2010-05-15')

          raise ActiveRecord::RecordNotUnique,
                'PG::UniqueViolation: duplicate key value violates unique constraint "index_students_on_api_code"'
        end

        original.call
      end

      expect { synchronizer.synchronize! }.not_to raise_error

      # Houve exatamente uma colisão antes do retry bem-sucedido
      expect(collisions).to eq(1)
      expect(Student.where(api_code: 99999).count).to eq(1)

      # O retry encontrou o registro do outro worker e aplicou os dados da API
      expect(Student.find_by(api_code: 99999).name).to eq('ALUNO TESTE')
    end

    it 'reraises RecordNotUnique from a different constraint without retrying' do
      call_count = 0

      allow(Student).to receive(:with_discarded).and_return(Student)

      # Violação em outra constraint (não api_code): deve propagar de imediato,
      # sem retry — o reset_record não resolveria e mascararia um bug real.
      allow_any_instance_of(Student).to receive(:save!).and_wrap_original do |_original|
        call_count += 1

        raise ActiveRecord::RecordNotUnique,
              'PG::UniqueViolation: duplicate key value violates unique constraint "index_students_on_some_other_column"'
      end

      expect { synchronizer.synchronize! }.to raise_error(ActiveRecord::RecordNotUnique, /some_other_column/)

      # Sem retry: apenas a tentativa inicial
      expect(call_count).to eq(1)
    end

    it 'gives up after MAX_RECORD_RETRIES when the api_code collision persists' do
      call_count = 0

      allow(Student).to receive(:with_discarded).and_return(Student)

      # Colisão de api_code que nunca se resolve: o retry deve esgotar o cap e
      # então propagar o erro, em vez de entrar em laço infinito.
      allow_any_instance_of(Student).to receive(:save!).and_wrap_original do |_original|
        call_count += 1

        raise ActiveRecord::RecordNotUnique,
              'PG::UniqueViolation: duplicate key value violates unique constraint "index_students_on_api_code"'
      end

      expect { synchronizer.synchronize! }.to raise_error(ActiveRecord::RecordNotUnique, /api_code/)

      # Tentativa inicial + MAX_RECORD_RETRIES retries, e para
      expect(call_count).to eq(StudentsSynchronizer::MAX_RECORD_RETRIES + 1)
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
