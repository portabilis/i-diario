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
  let(:grade) { create(:grade) }
  let(:classroom) { create(:classroom, unity: unity) }
  let(:knowledge_area) { create(:knowledge_area, group_descriptors: true) }
  let(:discipline) { create(:discipline, knowledge_area: knowledge_area) }

  let!(:grouper_discipline) do
    create(
      :discipline,
      knowledge_area: knowledge_area,
      grouper: true,
      api_code: "grouper:#{knowledge_area.id}"
    )
  end

  let(:api_code) { 'link-8180' }

  def mock_api_response(deleted_at: nil)
    {
      'vinculos' => [
        {
          'id' => api_code,
          'turma_id' => classroom.api_code,
          'servidor_id' => teacher.api_code,
          'updated_at' => Time.current.to_s,
          'deleted_at' => deleted_at,
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

  def synchronize_with(response)
    allow_any_instance_of(IeducarApi::TeacherDisciplineClassrooms).to receive(:fetch).and_return(response)
    synchronizer.synchronize!
  end

  def grouper_links
    TeacherDisciplineClassroom.kept.where(discipline_id: grouper_discipline.id)
  end

  before do
    teacher.reload
    discipline.reload
    grade.reload
    classroom.reload
  end

  describe 'when the teacher link is removed in i-Educar' do
    it 'removes the grouper link along with the regular ones' do
      synchronize_with(mock_api_response)

      expect(TeacherDisciplineClassroom.kept.count).to eq(2)
      expect(grouper_links.count).to eq(1)

      synchronize_with(mock_api_response(deleted_at: Time.current.to_s))

      expect(TeacherDisciplineClassroom.kept.count).to eq(0)
      expect(grouper_links.count).to eq(0)
    end

    it 'removes the grouper link even when the link no longer carries disciplines' do
      synchronize_with(mock_api_response)

      expect(grouper_links.count).to eq(1)

      response = mock_api_response(deleted_at: Time.current.to_s)
      response['vinculos'].first['disciplinas'] = []

      synchronize_with(response)

      expect(TeacherDisciplineClassroom.kept.count).to eq(0)
      expect(grouper_links.count).to eq(0)
    end

    # Cenario da rede que desligou o agrupamento de descritores no i-Educar depois que os
    # vinculos ja existiam: o agrupador precisa sair mesmo com a flag desligada
    it 'removes the grouper link when the knowledge area no longer groups descriptors' do
      synchronize_with(mock_api_response)

      expect(grouper_links.count).to eq(1)

      knowledge_area.update!(group_descriptors: false)

      synchronize_with(mock_api_response(deleted_at: Time.current.to_s))

      expect(TeacherDisciplineClassroom.kept.count).to eq(0)
      expect(grouper_links.count).to eq(0)
    end
  end

  describe 'when the teacher link remains active' do
    it 'keeps the grouper link' do
      synchronize_with(mock_api_response)
      synchronize_with(mock_api_response)

      expect(TeacherDisciplineClassroom.kept.count).to eq(2)
      expect(grouper_links.count).to eq(1)
    end

    it 'keeps the grouper link when another discipline of the same area is removed' do
      other_discipline = create(:discipline, knowledge_area: knowledge_area)

      response = mock_api_response
      response['vinculos'].first['disciplinas'] << {
        'id' => other_discipline.api_code,
        'tipo_nota' => 1,
        'serie_id' => grade.api_code
      }

      synchronize_with(response)

      expect(TeacherDisciplineClassroom.kept.count).to eq(3)

      synchronize_with(mock_api_response)

      expect(grouper_links.count).to eq(1)
      expect(TeacherDisciplineClassroom.kept.count).to eq(2)
    end
  end
end
