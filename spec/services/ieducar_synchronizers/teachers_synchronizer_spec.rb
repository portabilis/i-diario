require 'spec_helper'

RSpec.describe TeachersSynchronizer, type: :service do
  let(:synchronization) { create(:ieducar_api_synchronization) }
  let(:worker_batch) { create(:worker_batch) }
  let(:worker_state) { create(:worker_state, worker_batch: worker_batch) }

  describe 'unique index test' do
    it 'prevents creation of teachers with duplicate api_code' do
      teacher1 = create(:teacher, api_code: '12345', name: 'João Silva')
      expect(teacher1).to be_persisted

      expect {
        create(:teacher, api_code: '12345', name: 'João Silva Duplicado')
      }.to raise_error(ActiveRecord::RecordInvalid, /Api code já está em uso/)

      expect(Teacher.count).to eq(1)
      expect(Teacher.first.api_code).to eq('12345')
    end

    it 'prevents updating teacher to duplicate api_code' do
      teacher1 = create(:teacher, api_code: '12345', name: 'João Silva')
      teacher2 = create(:teacher, api_code: '67890', name: 'Maria Santos')

      expect(Teacher.count).to eq(2)

      expect {
        teacher2.update!(api_code: '12345')
      }.to raise_error(ActiveRecord::RecordInvalid, /Api code já está em uso/)

      teacher1.reload
      teacher2.reload
      expect(teacher1.api_code).to eq('12345')
      expect(teacher2.api_code).to eq('67890')
    end
  end

  describe '#update_teachers' do
    let(:synchronizer) { described_class.new(
      synchronization: synchronization,
      worker_batch: worker_batch,
      worker_state: worker_state,
      year: Date.current.year,
      unity_api_code: Unity.first.api_code,
      entity_id: Entity.first.id
    ) }

    context 'with valid data' do
      let(:teachers_data) do
        [
          double('teacher1', nome: 'João Silva', servidor_id: '12345', ativo: '1', cpf: '123.456.789-01'),
          double('teacher2', nome: 'Maria Santos', servidor_id: '67890', ativo: '1', cpf: '987.654.321-00')
        ]
      end

      it 'creates teachers correctly' do
        expect { synchronizer.send(:update_teachers, teachers_data) }.not_to raise_error

        expect(Teacher.count).to eq(2)
        expect(Teacher.find_by(api_code: '12345').name).to eq('João Silva')
        expect(Teacher.find_by(api_code: '67890').name).to eq('Maria Santos')
      end
    end

    context 'with invalid data' do
      let(:teachers_data) do
        [
          double('teacher1', nome: '', servidor_id: '12345', ativo: '1', cpf: '123.456.789-01'),
          double('teacher2', nome: 'Maria Santos', servidor_id: '67890', ativo: '1', cpf: '987.654.321-00')
        ]
      end

      it 'skips teachers with blank name' do
        synchronizer.send(:update_teachers, teachers_data)

        expect(Teacher.count).to eq(1)
        expect(Teacher.find_by(api_code: '67890')).to be_present
        expect(Teacher.find_by(api_code: '12345')).to be_nil
      end
    end

    context 'when trying to create teacher with duplicate api_code' do
      let!(:existing_teacher) { create(:teacher, api_code: '12345', name: 'João Silva') }
      let(:duplicate_teacher_data) do
        [
          double('teacher2', nome: 'João Silva Duplicado', servidor_id: '12345', ativo: '1', cpf: '123.456.789-01')
        ]
      end

      it 'updates existing teacher instead of creating duplicate' do
        expect {
          synchronizer.send(:update_teachers, duplicate_teacher_data)
        }.not_to raise_error

        existing_teacher.reload
        expect(existing_teacher.name).to eq('João Silva Duplicado')
        expect(Teacher.count).to eq(1)
      end
    end
  end

  describe 'integration with uniqueness validation' do
    it 'updates existing teachers instead of creating duplicates' do
      existing_teacher = create(:teacher, api_code: '12345', name: 'João Silva')

      duplicate_data = [
        double('teacher1', nome: 'João Silva Atualizado', servidor_id: '12345', ativo: '1', cpf: '123.456.789-01')
      ]

      synchronizer = described_class.new(
        synchronization: synchronization,
        worker_batch: worker_batch,
        worker_state: worker_state,
        year: Date.current.year,
        unity_api_code: Unity.first.api_code,
        entity_id: Entity.first.id
      )

      expect { synchronizer.send(:update_teachers, duplicate_data) }.not_to raise_error

      existing_teacher.reload
      expect(existing_teacher.name).to eq('João Silva Atualizado')
      expect(Teacher.count).to eq(1)
    end

    it 'allows synchronizing data with unique api_codes' do
      unique_data = [
        double('teacher1', nome: 'João Silva', servidor_id: '12345', ativo: '1', cpf: '123.456.789-01'),
        double('teacher2', nome: 'Maria Santos', servidor_id: '67890', ativo: '1', cpf: '987.654.321-00')
      ]

      synchronizer = described_class.new(
        synchronization: synchronization,
        worker_batch: worker_batch,
        worker_state: worker_state,
        year: Date.current.year,
        unity_api_code: Unity.first.api_code,
        entity_id: Entity.first.id
      )

      expect { synchronizer.send(:update_teachers, unique_data) }.not_to raise_error
      expect(Teacher.count).to eq(2)
    end
  end

  describe 'race condition handling' do
    let(:synchronizer) do
      described_class.new(
        synchronization: synchronization,
        worker_batch: worker_batch,
        worker_state: worker_state,
        year: Date.current.year,
        unity_api_code: Unity.first.api_code,
        entity_id: Entity.first.id
      )
    end

    let(:teachers_data) do
      [double('teacher', nome: 'João Silva', servidor_id: '12345', ativo: '1', cpf: '123.456.789-01')]
    end

    it 'handles race condition when another process inserts the same teacher between SELECT and INSERT' do
      call_count = 0

      allow(Teacher).to receive(:with_discarded).and_return(Teacher)

      allow(Teacher).to receive(:find_or_initialize_by)
        .with(api_code: '12345')
        .and_wrap_original do |method, *args|
          call_count += 1
          result = method.call(*args)

          # Na primeira chamada, simula a race: o INSERT do nosso worker bate
          # na constraint do banco (outro worker comitou antes), levantando
          # RecordNotUnique. Em paralelo, cria o registro "concorrente" para
          # que o retry encontre-o e apenas atualize.
          if call_count == 1 && result.new_record?
            allow(result).to receive(:save!).and_wrap_original do |_original|
              Teacher.create!(api_code: '12345', name: 'Criado por outro worker')
              raise ActiveRecord::RecordNotUnique,
                    'PG::UniqueViolation: duplicate key value violates unique constraint ' \
                    '"index_teachers_on_api_code_unique"'
            end
          end

          result
        end

      expect { synchronizer.send(:update_teachers, teachers_data) }.not_to raise_error

      expect(Teacher.where(api_code: '12345').count).to eq(1)

      # O retry deve ter sido executado (2 chamadas ao find_or_initialize_by)
      expect(call_count).to eq(2)
    end
  end
end
