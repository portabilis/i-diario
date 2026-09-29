require 'rails_helper'

RSpec.describe TeacherDisciplineClassroomsSynchronizer, type: :service do
  let(:synchronization) { create(:ieducar_api_synchronization) }
  let(:worker_batch) { create(:worker_batch) }
  let(:worker_state) { create(:worker_state, worker_batch: worker_batch) }
  let(:unity) { create(:unity) }
  let(:entity) { Entity.first || create(:entity) }
  let(:year) { Date.current.year }

  let(:synchronizer) do
    described_class.new(
      synchronization: synchronization,
      worker_batch: worker_batch,
      worker_state: worker_state,
      entity_id: entity.id,
      year: year,
      unity_api_code: unity.api_code
    )
  end

  let!(:previous_teacher) { create(:teacher) }
  let!(:current_teacher) { create(:teacher) }
  let!(:discipline) { create(:discipline) }
  let!(:grade) { create(:grade) }
  let!(:classroom) { create(:classroom, unity: unity) }

  let(:api_code) { 'link-123' }

  def stub_link(teacher)
    allow_any_instance_of(IeducarApi::TeacherDisciplineClassrooms).to receive(:fetch).and_return(
      'vinculos' => [
        {
          'id' => api_code,
          'turma_id' => classroom.api_code,
          'servidor_id' => teacher.api_code,
          'updated_at' => Time.current.to_s,
          'turno_id' => 1,
          'permite_lancar_faltas_componente' => true,
          'disciplinas' => [
            {
              'id' => discipline.api_code,
              'tipo_nota' => 1,
              'serie_id' => grade.api_code
            }
          ]
        }
      ]
    )
  end

  it 'discards the link of the previous teacher when the link moves to another teacher' do
    stub_link(previous_teacher)
    synchronizer.synchronize!

    previous_link = TeacherDisciplineClassroom.find_by!(api_code: api_code, teacher_id: previous_teacher.id)

    stub_link(current_teacher)
    synchronizer.synchronize!

    current_link = TeacherDisciplineClassroom.find_by!(api_code: api_code, teacher_id: current_teacher.id)

    expect(previous_link.reload).to be_discarded
    expect(current_link).not_to be_discarded
    expect(TeacherDisciplineClassroom.kept.where(api_code: api_code).count).to eq(1)
  end

  it 'keeps the link of the teacher when the link does not change' do
    stub_link(current_teacher)
    synchronizer.synchronize!
    synchronizer.synchronize!

    expect(TeacherDisciplineClassroom.kept.where(api_code: api_code, teacher_id: current_teacher.id).count).to eq(1)
  end
end
