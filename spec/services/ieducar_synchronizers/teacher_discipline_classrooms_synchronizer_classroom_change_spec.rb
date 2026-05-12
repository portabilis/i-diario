require 'rails_helper'

RSpec.describe TeacherDisciplineClassroomsSynchronizer do
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

  let(:teacher) { create(:teacher) }
  let(:discipline) { create(:discipline) }
  let(:grade) { create(:grade) }
  let(:classroom_a) { create(:classroom, unity: unity) }
  let(:classroom_b) { create(:classroom, unity: unity) }

  let(:api_code) { "link-123" }

  def mock_api_response(turma_api_code)
    {
      'vinculos' => [
        {
          'id' => api_code,
          'turma_id' => turma_api_code,
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
    }
  end

  it 'discards Classroom B when moving back to Classroom A' do
    teacher.reload
    discipline.reload
    grade.reload
    classroom_a.reload
    classroom_b.reload

    # 1. Initially at Classroom A
    allow_any_instance_of(IeducarApi::TeacherDisciplineClassrooms)
      .to receive(:fetch).and_return(mock_api_response(classroom_a.api_code))
    synchronizer.synchronize!

    expect(TeacherDisciplineClassroom.kept.count).to eq(1)
    link_a = TeacherDisciplineClassroom.kept.last
    expect(link_a.classroom_id).to eq(classroom_a.id)
    expect(link_a).not_to be_discarded

    # 2. Move to Classroom B
    allow_any_instance_of(IeducarApi::TeacherDisciplineClassrooms)
      .to receive(:fetch).and_return(mock_api_response(classroom_b.api_code))
    synchronizer.synchronize!

    expect(TeacherDisciplineClassroom.kept.count).to eq(1)
    link_b = TeacherDisciplineClassroom.kept.last
    expect(link_b.classroom_id).to eq(classroom_b.id)
    expect(link_a.reload).to be_discarded

    # 3. Move back to Classroom A
    allow_any_instance_of(IeducarApi::TeacherDisciplineClassrooms)
      .to receive(:fetch).and_return(mock_api_response(classroom_a.api_code))
    synchronizer.synchronize!

    # link_b should be discarded after moving back to Classroom A
    expect(TeacherDisciplineClassroom.kept.count).to eq(1)
    expect(TeacherDisciplineClassroom.kept.last.classroom_id).to eq(classroom_a.id)
    expect(link_b.reload).to be_discarded
  end
end
