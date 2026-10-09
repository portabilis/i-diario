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

  # Executa só a sincronização, sem o método de classe: ele recebe worker_state_id, engole
  # StandardError em worker_state.mark_with_error! e enfileira SynchronizerBuilderEnqueueWorker
  # a cada chamada — ruído nos exemplos que rodam o sincronizador mais de uma vez.
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

  def enroll(target_student, target_unity, joined_at:)
    create(
      :student_enrollment_classroom,
      student_enrollment: create(:student_enrollment, student: target_student),
      classrooms_grade: create(:classrooms_grade, classroom: create(:classroom, unity: target_unity)),
      joined_at: joined_at
    )
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
      before do
        student.update(api_code: existing_api_code)
        unity
      end

      it 'does not duplicate the relation between deficiency and student' do
        VCR.use_cassette('all_deficiencies', allow_playback_repeats: true) do
          2.times { synchronize }
        end

        expect(DeficiencyStudent.with_discarded.by_student_id(student.id).count).to eq 1
      end

      it 'does not rewrite the relation on the second run' do
        VCR.use_cassette('all_deficiencies', allow_playback_repeats: true) do
          synchronize
          deficiency_student = DeficiencyStudent.by_student_id(student.id).first

          expect { synchronize }.not_to change { deficiency_student.reload.updated_at }
        end
      end
    end

    context 'when the relation does not exist yet' do
      before do
        student.update(api_code: existing_api_code)
        unity
      end

      it 'stores the synchronized unity in the relation' do
        VCR.use_cassette('all_deficiencies', allow_playback_repeats: true) { synchronize }

        expect(DeficiencyStudent.by_student_id(student.id).first.unity_id).to eq unity.id
      end
    end

    context 'when a relation already exists for the student' do
      before do
        student.update(api_code: existing_api_code)
        unity
      end

      it 'reuses the one left without unity by an older synchronization' do
        deficiency_student = create(
          :deficiency_student,
          deficiency: deficiency,
          student: student,
          unity_id: nil
        )

        VCR.use_cassette('all_deficiencies', allow_playback_repeats: true) { synchronize }

        expect(DeficiencyStudent.with_discarded.by_student_id(student.id).count).to eq 1
        expect(deficiency_student.reload.unity_id).to eq unity.id
      end

      it 'reactivates the discarded one instead of creating another' do
        deficiency_student = create(
          :deficiency_student,
          deficiency: deficiency,
          student: student,
          unity_id: unity.id
        )
        deficiency_student.discard

        VCR.use_cassette('all_deficiencies', allow_playback_repeats: true) { synchronize }

        expect(DeficiencyStudent.with_discarded.by_student_id(student.id).count).to eq 1
        expect(deficiency_student.reload).not_to be_discarded
      end

      # Reativar o descartado havendo um ativo deixaria os dois ativos: as chaves do índice
      # único seriam diferentes (a escola e o COALESCE do nulo), então nada barraria.
      it 'prefers the kept one over reactivating a discarded one' do
        discarded = create(:deficiency_student, deficiency: deficiency, student: student, unity_id: unity.id)
        discarded.discard
        kept = create(:deficiency_student, deficiency: deficiency, student: student, unity_id: nil)

        VCR.use_cassette('all_deficiencies', allow_playback_repeats: true) { synchronize }

        expect(DeficiencyStudent.by_student_id(student.id).count).to eq 1
        expect(discarded.reload).to be_discarded
        expect(kept.reload.unity_id).to eq unity.id
      end
    end

    context 'when another worker creates the same relation concurrently' do
      let(:collision_error) {
        'PG::UniqueViolation: duplicate key value violates unique constraint ' \
        '"idx_deficiency_students_unique_kept"'
      }

      # A deficiência precisa existir antes da sincronização: criada só dentro do stub, ela
      # nasceria depois da que o sincronizador já registrou pelo mesmo api_code, e o vínculo
      # do "outro worker" apontaria para a duplicada.
      before do
        student.update(api_code: existing_api_code)
        unity
        deficiency
      end

      it 'retries and reuses the relation created by the other worker' do
        collisions = 0

        allow_any_instance_of(DeficiencyStudent).to receive(:save!).and_wrap_original do |original|
          if collisions.zero?
            collisions += 1
            DeficiencyStudent.create!(deficiency: deficiency, student: student, unity_id: unity.id)

            raise ActiveRecord::RecordNotUnique, collision_error
          end

          original.call
        end

        VCR.use_cassette('all_deficiencies', allow_playback_repeats: true) { synchronize }

        expect(collisions).to eq 1
        expect(DeficiencyStudent.with_discarded.by_student_id(student.id).count).to eq 1
      end

      it 'reraises RecordNotUnique from a different constraint without retrying' do
        call_count = 0

        allow_any_instance_of(DeficiencyStudent).to receive(:save!).and_wrap_original do |_original|
          call_count += 1

          raise ActiveRecord::RecordNotUnique,
                'PG::UniqueViolation: duplicate key value violates unique constraint "index_audits_on_associated"'
        end

        expect {
          VCR.use_cassette('all_deficiencies', allow_playback_repeats: true) { synchronize }
        }.to raise_error(ActiveRecord::RecordNotUnique, /index_audits_on_associated/)

        expect(call_count).to eq 1
      end

      it 'gives up after MAX_RECORD_RETRIES when the collision persists' do
        call_count = 0

        allow_any_instance_of(DeficiencyStudent).to receive(:save!).and_wrap_original do |_original|
          call_count += 1

          raise ActiveRecord::RecordNotUnique, collision_error
        end

        expect {
          VCR.use_cassette('all_deficiencies', allow_playback_repeats: true) { synchronize }
        }.to raise_error(ActiveRecord::RecordNotUnique, /idx_deficiency_students_unique_kept/)

        expect(call_count).to eq described_class::MAX_RECORD_RETRIES + 1
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

  # Exercitado direto porque a cassette cobre uma escola só (escola=1), e o desempate por
  # enturmação só roda quando várias escolas vêm na mesma execução — o caso da sincronização
  # parcial, que é a que roda no dia a dia.
  describe '#target_unity_id' do
    let(:first_unity) { create(:unity) }
    let(:second_unity) { create(:unity) }

    def target_unity_id_for(unity_ids)
      synchronizer = described_class.new(
        synchronization: synchronization,
        worker_batch: worker_batch,
        worker_state: worker_state,
        year: Date.current.year,
        unity_api_code: unity_id,
        entity_id: Entity.first.id
      )
      synchronizer.send(:unity_id=, unity_ids)
      synchronizer.send(:target_unity_id, student.id)
    end

    context 'when more than one unity is synchronized' do
      it 'uses the unity of the most recent active enrollment among them' do
        enroll(student, first_unity, joined_at: '2026-01-01')
        enroll(student, second_unity, joined_at: '2026-06-01')

        expect(target_unity_id_for([first_unity.id, second_unity.id])).to eq second_unity.id
      end

      it 'returns nil when no active enrollment belongs to the synchronized unities' do
        enroll(student, create(:unity), joined_at: '2026-06-01')

        expect(target_unity_id_for([first_unity.id, second_unity.id])).to be_nil
      end
    end

    context 'when a single unity is synchronized' do
      it 'uses it even when the same unity comes repeated in the api code list' do
        expect(target_unity_id_for([first_unity.id, first_unity.id])).to eq first_unity.id
      end
    end
  end
end
