require 'rails_helper'

RSpec.describe ClassroomsSynchronizer do
  describe '#should_destroy_old_grades?' do
    let(:synchronization) { create(:ieducar_api_synchronization, full_synchronization: full_synchronization) }
    let(:worker_batch) { create(:worker_batch) }
    let(:worker_state) { create(:worker_state, worker_batch: worker_batch) }
    let(:unity) { create(:unity) }
    let(:entity_id) { Entity.first.id }

    let(:synchronizer) do
      described_class.new(
        synchronization: synchronization,
        worker_batch: worker_batch,
        worker_state: worker_state,
        entity_id: entity_id,
        year: Date.current.year,
        unity_api_code: unity.api_code
      )
    end

    context 'when full_synchronization is true' do
      let(:full_synchronization) { true }

      it 'returns true regardless of classroom updated_at' do
        result = synchronizer.send(:should_destroy_old_grades?, '2020-01-01')

        expect(result).to be true
      end
    end

    context 'when partial synchronization' do
      let(:full_synchronization) { false }

      context 'when @modified_at is blank' do
        before do
          synchronizer.instance_variable_set(:@modified_at, nil)
        end

        it 'returns true (safe fallback)' do
          result = synchronizer.send(:should_destroy_old_grades?, '2020-01-01')

          expect(result).to be true
        end
      end

      context 'when @modified_at is set' do
        let(:modified_at) { Time.zone.parse('2025-12-14 00:00:00') }

        before do
          synchronizer.instance_variable_set(:@modified_at, modified_at)
        end

        # Cenario 1: turma não foi modificada, apenas algumas séries foram
        # Nesse caso, não devemos excluir grades antigas pois a API não retornou todas
        context 'when classroom updated_at is before modified_at' do
          it 'returns false to prevent improper deletion' do
            classroom_updated_at = '2025-12-01 10:00:00'

            result = synchronizer.send(:should_destroy_old_grades?, classroom_updated_at)

            expect(result).to be false
          end
        end

        # Cenario 2: turma foi modificada (ex: série removida intencionalmente)
        # A condição t.updated_at >= modified garante que todas as séries foram retornadas
        context 'when classroom updated_at is equal to modified_at' do
          it 'returns true to allow deletion' do
            classroom_updated_at = '2025-12-14 00:00:00'

            result = synchronizer.send(:should_destroy_old_grades?, classroom_updated_at)

            expect(result).to be true
          end
        end

        context 'when classroom updated_at is after modified_at' do
          it 'returns true to allow deletion' do
            classroom_updated_at = '2025-12-15 10:00:00'

            result = synchronizer.send(:should_destroy_old_grades?, classroom_updated_at)

            expect(result).to be true
          end
        end
      end
    end
  end

  describe '#destroy_old_grades' do
    let(:synchronization) { create(:ieducar_api_synchronization, full_synchronization: false) }
    let(:worker_batch) { create(:worker_batch) }
    let(:worker_state) { create(:worker_state, worker_batch: worker_batch) }
    let(:unity) { create(:unity) }
    let(:entity_id) { Entity.first.id }
    let(:classroom) { create(:classroom, unity: unity) }
    let(:grade_to_keep) { create(:grade) }
    let(:grade_to_remove) { create(:grade) }
    let(:exam_rule) { create(:exam_rule) }

    let(:synchronizer) do
      described_class.new(
        synchronization: synchronization,
        worker_batch: worker_batch,
        worker_state: worker_state,
        entity_id: entity_id,
        year: Date.current.year,
        unity_api_code: unity.api_code
      )
    end

    before do
      create(:classrooms_grade, classroom: classroom, grade: grade_to_keep, exam_rule: exam_rule)
      create(:classrooms_grade, classroom: classroom, grade: grade_to_remove, exam_rule: exam_rule)
    end

    context 'when should_destroy_old_grades? returns false' do
      before do
        synchronizer.instance_variable_set(:@modified_at, Time.zone.parse('2025-12-14 00:00:00'))
      end

      it 'does not destroy any ClassroomsGrade' do
        classroom_updated_at = '2025-12-01 10:00:00'

        expect {
          synchronizer.send(:destroy_old_grades, [grade_to_keep.id], classroom.classrooms_grades, classroom_updated_at)
        }.not_to change(ClassroomsGrade, :count)
      end
    end

    context 'when should_destroy_old_grades? returns true' do
      before do
        synchronizer.instance_variable_set(:@modified_at, Time.zone.parse('2025-12-14 00:00:00'))
      end

      it 'destroys ClassroomsGrade not in the grades_ids list' do
        classroom_updated_at = '2025-12-15 10:00:00'

        expect {
          synchronizer.send(:destroy_old_grades, [grade_to_keep.id], classroom.classrooms_grades, classroom_updated_at)
        }.to change(ClassroomsGrade, :count).by(-1)

        expect(ClassroomsGrade.exists?(grade_id: grade_to_keep.id)).to be true
        expect(ClassroomsGrade.exists?(grade_id: grade_to_remove.id)).to be false
      end
    end

    context 'when full_synchronization is true' do
      let(:synchronization) { create(:ieducar_api_synchronization, full_synchronization: true) }

      it 'always destroys ClassroomsGrade regardless of dates' do
        synchronizer.instance_variable_set(:@modified_at, Time.zone.parse('2025-12-14 00:00:00'))
        classroom_updated_at = '2020-01-01 00:00:00'

        expect {
          synchronizer.send(:destroy_old_grades, [grade_to_keep.id], classroom.classrooms_grades, classroom_updated_at)
        }.to change(ClassroomsGrade, :count).by(-1)

        expect(ClassroomsGrade.exists?(grade_id: grade_to_keep.id)).to be true
        expect(ClassroomsGrade.exists?(grade_id: grade_to_remove.id)).to be false
      end
    end
  end
end
