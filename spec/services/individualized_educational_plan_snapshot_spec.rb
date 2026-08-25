require 'rails_helper'

# Estrutura canônica congelada de um PEI. O foco aqui são os campos de identificação vindos do
# prefill (birth_date/guardians/diagnosis/shift) — comportamento novo do snapshot e o de maior
# risco (é o que a versão publicada congela para sempre). O restante do conteúdo (nomes, opções,
# seções 4/5) é coberto pelo publisher_spec.
RSpec.describe IndividualizedEducationalPlanSnapshot, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  let(:plan) { create(:individualized_educational_plan) }

  describe '.build identification' do
    it 'freezes the student data fields from the prefill' do
      allow(IndividualizedEducationalPlanPrefill).to receive(:student_data)
        .with(plan.student, classroom: nil)
        .and_return(birth_date: '10/03/2015', guardians: 'Maria e João',
                    guardians_unavailable: false, diagnosis: 'TEA', shift: 'Matutino')

      identification = described_class.build(plan)['identification']

      expect(identification['birth_date']).to eq('10/03/2015')
      expect(identification['guardians']).to eq('Maria e João')
      expect(identification['guardians_unavailable']).to eq(false)
      expect(identification['diagnosis']).to eq('TEA')
      expect(identification['shift']).to eq('Matutino')
    end

    it 'records guardians as unavailable when i-Educar could not be reached' do
      allow(IndividualizedEducationalPlanPrefill).to receive(:student_data)
        .and_return(birth_date: nil, guardians: nil, guardians_unavailable: true,
                    diagnosis: nil, shift: nil)

      identification = described_class.build(plan)['identification']

      expect(identification['guardians']).to be_nil
      expect(identification['guardians_unavailable']).to eq(true)
    end

    it 'uses the prefetched student_data instead of calling the prefill' do
      expect(IndividualizedEducationalPlanPrefill).not_to receive(:student_data)
      prefetched = { birth_date: '01/01/2015', guardians: 'Responsável X',
                     guardians_unavailable: false, diagnosis: nil, shift: 'Vespertino' }

      identification = described_class.build(plan, student_data: prefetched)['identification']

      expect(identification['guardians']).to eq('Responsável X')
      expect(identification['shift']).to eq('Vespertino')
    end
  end

  # Ids reais dos registros de origem, gravados ao lado dos nomes/descrições para eventual
  # restauração operacional. São aditivos: não substituem nem alteram os campos exibidos.
  describe '.build record ids' do
    it 'records the ids of the identification records next to their names' do
      unity = create(:unity)
      regent = create(:teacher)
      classroom = create(:classroom, unity: unity, regent_api_code: regent.api_code)
      plan = create(:individualized_educational_plan, :with_aee_teacher)
      review_date = create(:iep_review_date, iep: plan, review_date: Date.current)

      identification = described_class.build(plan, student_data: {}, classroom: classroom)['identification']

      expect(identification['plan_id']).to eq(plan.id)
      expect(identification['student_id']).to eq(plan.student_id)
      expect(identification['unity_id']).to eq(unity.id)
      expect(identification['classroom_id']).to eq(classroom.id)
      expect(identification['teacher_id']).to eq(regent.id)
      expect(identification['aee_teacher_id']).to eq(plan.aee_teacher_id)
      expect(identification['review_date_ids']).to eq([review_date.id])
    end

    it 'leaves the context ids empty when the plan is opened without a classroom' do
      plan = create(:individualized_educational_plan)

      identification = described_class.build(plan, student_data: {})['identification']

      expect(identification['unity_id']).to be_nil
      expect(identification['classroom_id']).to be_nil
      expect(identification['teacher_id']).to be_nil
    end

    # Cada multi-select tem a própria chave de ids: sem isso não dá para saber a que categoria
    # um id pertence sem reler iep_options.kind — justamente o registro que pode ter sumido.
    it 'keeps each multi-select id under its own category' do
      plan = create(:individualized_educational_plan)
      communication = create(:iep_option, :communication_profile, description: 'Verbal')
      autonomy = create(:iep_option, kind: IepOptionKinds::AUTONOMY, description: 'Parcial')
      create(:iep_selected_option, iep: plan, iep_option: communication)
      create(:iep_selected_option, iep: plan, iep_option: autonomy)

      characterization = described_class.build(plan, student_data: {})['characterization']

      expect(characterization['communication_profile']).to eq(['Verbal'])
      expect(characterization['communication_profile_option_ids']).to eq([communication.id])
      expect(characterization['autonomy']).to eq(['Parcial'])
      expect(characterization['autonomy_option_ids']).to eq([autonomy.id])
      expect(characterization['social_interaction_profile_option_ids']).to eq([])
    end

    it 'records the support team option ids by category' do
      plan = create(:individualized_educational_plan)
      accompaniment = create(:iep_option, kind: IepOptionKinds::ACCOMPANIMENT, description: 'Fonoaudiólogo')
      support_type = create(:iep_option, :support_type, description: 'Profissional de apoio')
      create(:iep_selected_option, iep: plan, iep_option: accompaniment)
      create(:iep_selected_option, iep: plan, iep_option: support_type)

      support_team = described_class.build(plan, student_data: {})['support_team']

      expect(support_team['accompaniment_option_ids']).to eq([accompaniment.id])
      expect(support_team['support_type_option_ids']).to eq([support_type.id])
    end

    it 'records the ids of a curricular planning line and of its accommodations by category' do
      plan = create(:individualized_educational_plan)
      review_date = create(:iep_review_date, iep: plan, review_date: Date.current)
      discipline = create(:discipline)
      planning = create(:iep_curricular_planning, iep: plan, iep_review_date: review_date,
                                                  discipline: discipline, long_term_goal: 'Meta')
      instructional = create(:iep_option, :instructional_accommodation, description: 'Materiais concretos')
      environmental = create(:iep_option, kind: IepOptionKinds::ENVIRONMENTAL_ACCOMMODATION,
                                          description: 'Sentar à frente')
      create(:iep_curricular_planning_option, iep_curricular_planning: planning, iep_option: instructional)
      create(:iep_curricular_planning_option, iep_curricular_planning: planning, iep_option: environmental)

      line = described_class.build(plan, student_data: {})['curricular_plannings'].first

      expect(line['id']).to eq(planning.id)
      expect(line['iep_review_date_id']).to eq(review_date.id)
      expect(line['discipline_id']).to eq(discipline.id)
      expect(line['knowledge_area_id']).to be_nil
      expect(line['instructional_accommodation_option_ids']).to eq([instructional.id])
      expect(line['environmental_accommodation_option_ids']).to eq([environmental.id])
      expect(line['assessment_accommodation_option_ids']).to eq([])
    end

    it 'records the knowledge area id on a line by field of experience' do
      plan = create(:individualized_educational_plan)
      review_date = create(:iep_review_date, iep: plan, review_date: Date.current)
      knowledge_area = create(:knowledge_area)
      evaluation = create(:iep_periodic_evaluation, :by_knowledge_area, iep: plan,
                                                    iep_review_date: review_date,
                                                    knowledge_area: knowledge_area,
                                                    acquired_skills: 'Habilidades')

      line = described_class.build(plan, student_data: {})['periodic_evaluations'].first

      expect(line['id']).to eq(evaluation.id)
      expect(line['knowledge_area_id']).to eq(knowledge_area.id)
      expect(line['discipline_id']).to be_nil
    end
  end
end
