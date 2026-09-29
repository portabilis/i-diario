require 'rails_helper'

RSpec.describe TeacherUnificationsSynchronizer, type: :service do
  let(:synchronization) { create(:ieducar_api_synchronization) }
  let(:worker_batch) { create(:worker_batch) }
  let(:worker_state) { create(:worker_state, worker_batch: worker_batch) }
  let(:entity) { Entity.first || create(:entity) }

  let(:synchronizer) do
    described_class.new(
      synchronization: synchronization,
      worker_batch: worker_batch,
      worker_state: worker_state,
      entity_id: entity.id
    )
  end

  let!(:main_teacher) { create(:teacher) }
  let!(:secondary_teacher) { create(:teacher) }
  let(:unified_at) { '2026-01-10 10:00:00' }

  let(:classroom) { create(:classroom) }
  let(:discipline) { create(:discipline) }
  let(:grade) { create(:grade) }

  def unification_payload(main_teacher, secondary_teacher)
    {
      'main_id' => main_teacher.api_code,
      'duplicates_id' => [secondary_teacher.api_code],
      'created_at' => unified_at,
      'active' => true
    }
  end

  def stub_unifications(*unifications)
    allow_any_instance_of(IeducarApi::TeacherUnifications)
      .to receive(:fetch).and_return('unificacoes' => unifications)
  end

  def create_link(teacher, api_code: 'link-1')
    create(
      :teacher_discipline_classroom,
      api_code: api_code,
      teacher: teacher,
      classroom: classroom,
      discipline: discipline,
      grade: grade
    )
  end

  context 'when the unification is new' do
    let!(:secondary_link) { create_link(secondary_teacher) }

    before { stub_unifications(unification_payload(main_teacher, secondary_teacher)) }

    it 'records the unification and unifies the teachers' do
      synchronizer.synchronize!

      expect(TeacherUnification.find_by(teacher_id: main_teacher.id)).to be_present
      expect(secondary_link.reload.teacher_id).to eq(main_teacher.id)
      expect(secondary_teacher.reload).to be_discarded
    end
  end

  context 'when the main teacher already has a link identical to the secondary teacher' do
    let!(:main_link) { create_link(main_teacher) }
    let!(:repeated_link) { create_link(secondary_teacher) }

    before { stub_unifications(unification_payload(main_teacher, secondary_teacher)) }

    it 'completes the unification' do
      synchronizer.synchronize!

      expect(repeated_link.reload).to be_discarded
      expect(main_link.reload).not_to be_discarded
      expect(secondary_teacher.reload).to be_discarded
    end
  end

  context 'when a recorded unification was left incomplete' do
    let!(:remaining_link) { create_link(secondary_teacher) }

    before do
      TeacherUnification.create!(teacher: main_teacher, unified_at: unified_at, active: true)
      stub_unifications(unification_payload(main_teacher, secondary_teacher))
    end

    it 'unifies the remaining records' do
      synchronizer.synchronize!

      expect(remaining_link.reload.teacher_id).to eq(main_teacher.id)
      expect(secondary_teacher.reload).to be_discarded
    end
  end

  context 'when a recorded unification is complete' do
    before do
      TeacherUnification.create!(teacher: main_teacher, unified_at: unified_at, active: true)
      secondary_teacher.discard
      stub_unifications(unification_payload(main_teacher, secondary_teacher))
    end

    it 'does not unify again' do
      expect(TeacherUnification::UnificationService).not_to receive(:new)

      synchronizer.synchronize!
    end
  end

  context 'when a recorded unification is inactive' do
    before do
      TeacherUnification.create!(teacher: main_teacher, unified_at: unified_at, active: false)
      stub_unifications(unification_payload(main_teacher, secondary_teacher).merge('active' => false))
    end

    it 'does not unify the teachers' do
      expect(TeacherUnification::UnificationService).not_to receive(:new)

      synchronizer.synchronize!

      expect(secondary_teacher.reload).not_to be_discarded
    end
  end

  context 'when one unification fails' do
    let!(:other_main_teacher) { create(:teacher) }
    let!(:other_secondary_teacher) { create(:teacher) }

    before do
      stub_unifications(
        unification_payload(main_teacher, secondary_teacher),
        unification_payload(other_main_teacher, other_secondary_teacher)
      )

      failing_service = instance_double(TeacherUnification::UnificationService)
      allow(failing_service).to receive(:run!).and_raise(ActiveRecord::RecordNotUnique, 'duplicate key')
      allow(TeacherUnification::UnificationService).to receive(:new).and_call_original
      allow(TeacherUnification::UnificationService)
        .to receive(:new).with(main_teacher, [secondary_teacher]).and_return(failing_service)
    end

    it 'raises the error' do
      expect { synchronizer.synchronize! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'does not record the failed unification, so the next synchronization retries it' do
      expect { synchronizer.synchronize! }.to raise_error(ActiveRecord::RecordNotUnique)

      expect(TeacherUnification.find_by(teacher_id: main_teacher.id)).to be_nil
    end

    it 'unifies the other teachers' do
      expect { synchronizer.synchronize! }.to raise_error(ActiveRecord::RecordNotUnique)

      expect(TeacherUnification.find_by(teacher_id: other_main_teacher.id)).to be_present
      expect(other_secondary_teacher.reload).to be_discarded
    end
  end
end
