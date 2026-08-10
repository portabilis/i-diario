require 'rails_helper'

RSpec.describe DeficienciesSynchronizer do
  let(:synchronization) { create(:ieducar_api_synchronization) }
  let(:worker_batch) { create(:worker_batch) }
  let(:worker_state) { create(:worker_state, worker_batch: worker_batch) }
  let(:unity_id) { '1' }

  let(:student) { create(:student) }
  let(:existing_api_code) { '14612' }

  let(:unity) {
    Unity.create(
      id: unity_id,
      api_code: unity_id,
      name: 'test',
      email: 'test@test.com',
      phone: '(11) 11111111',
      author: create(:user),
      unit_type: 'school_unit'
    )
  }
  let(:deficiency) {
    Deficiency.create(
      id: 4,
      api_code: '4',
      name: 'Surdez'
    )
  }

  # Executa apenas a sincronização, sem o controle de worker_batch/worker_state do método de
  # classe, que não pode ser reexecutado na mesma instância.
  def synchronize
    described_class.new(
      synchronization: synchronization,
      worker_batch: worker_batch,
      worker_state: worker_state,
      year: Date.current.year,
      unity_api_code: unity_id,
      entity_id: Entity.first.id
    ).synchronize!
  end

  describe '#synchronize!' do
    context 'when params are valid' do
      it 'creates deficiencies' do
        VCR.use_cassette('all_deficiencies') do
          described_class.synchronize!(
            synchronization: synchronization,
            worker_batch: worker_batch,
            worker_state_id: worker_state.id,
            year: Date.current.year,
            unity_api_code: unity_id,
            entity_id: Entity.first.id
          )
          expect(Deficiency.count).to eq 35
        end
      end

      it 'creates relation between deficiencies and students' do
        VCR.use_cassette('all_deficiencies') do
          student.update(api_code: existing_api_code)
          described_class.synchronize!(
            synchronization: synchronization,
            worker_batch: worker_batch,
            worker_state_id: worker_state.id,
            year: Date.current.year,
            unity_api_code: unity_id,
            entity_id: Entity.first.id
          )
          expect(DeficiencyStudent.count).to eq 1
        end
      end
    end

    context 'when the synchronization runs more than once' do
      before { student.update(api_code: existing_api_code) }

      it 'does not duplicate the relation between deficiency and student' do
        VCR.use_cassette('all_deficiencies', allow_playback_repeats: true) do
          unity
          2.times { synchronize }
        end

        expect(DeficiencyStudent.count).to eq 1
      end

      it 'stores the synchronized unity in the relation' do
        VCR.use_cassette('all_deficiencies', allow_playback_repeats: true) do
          unity
          synchronize
        end

        expect(DeficiencyStudent.first.unity_id).to eq unity.id
      end

      it 'reuses a relation left without unity by an older synchronization' do
        deficiency_student = create(
          :deficiency_student,
          deficiency: deficiency,
          student: student,
          unity_id: nil
        )

        VCR.use_cassette('all_deficiencies', allow_playback_repeats: true) do
          unity
          synchronize
        end

        expect(DeficiencyStudent.by_student_id(student.id).count).to eq 1
        expect(deficiency_student.reload.unity_id).to eq unity.id
      end
    end

    context 'when student is not informed anymore in deficiency' do

      it 'deletes deficiency when unity is valid' do
        create(
          :deficiency_student,
          deficiency: deficiency,
          unity_id: unity.id
        )
        expect(DeficiencyStudent.count).to eq 1
        VCR.use_cassette('all_deficiencies') do
          described_class.synchronize!(
            synchronization: synchronization,
            worker_batch: worker_batch,
            worker_state_id: worker_state.id,
            year: Date.current.year,
            unity_api_code: unity_id,
            entity_id: Entity.first.id
          )
          expect(DeficiencyStudent.count).to eq 0
        end
      end

      it 'deletes deficiency when unity is invalid' do
        create(
          :deficiency_student,
          deficiency: deficiency,
          unity_id: nil
        )
        expect(DeficiencyStudent.count).to eq 1
        VCR.use_cassette('all_deficiencies') do
          described_class.synchronize!(
            synchronization: synchronization,
            worker_batch: worker_batch,
            worker_state_id: worker_state.id,
            year: Date.current.year,
            unity_api_code: unity_id,
            entity_id: Entity.first.id
          )
          expect(DeficiencyStudent.count).to eq 0
        end
      end

      it 'deletes deficiency only from invalid unity' do
        another_unity = create(:unity)
        create(
          :deficiency_student,
          deficiency: deficiency,
          student: student,
          unity_id: another_unity.id
        )
        create(
          :deficiency_student,
          deficiency: deficiency,
          student: student,
          unity_id: nil
        )
        expect(DeficiencyStudent.count).to eq 2
        VCR.use_cassette('all_deficiencies') do
          described_class.synchronize!(
            synchronization: synchronization,
            worker_batch: worker_batch,
            worker_state_id: worker_state.id,
            year: Date.current.year,
            unity_api_code: unity_id,
            entity_id: Entity.first.id
          )
          expect(DeficiencyStudent.count).to eq 1
        end
      end

    end
  end
end
