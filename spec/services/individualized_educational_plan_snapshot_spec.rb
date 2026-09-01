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

  describe '.build record ids' do
    it 'records the ids of the identification records next to their names' do
      allow(IeducarApiConfiguration).to receive(:current).and_return(double(to_api: {}))
      allow(IeducarApi::Students).to receive(:new).and_return(double(fetch_by_id: {}))
      unity = create(:unity)
      regent = create(:teacher)
      classroom = create(:classroom, unity: unity, regent_api_code: regent.api_code)
      plan = create(:individualized_educational_plan, :with_aee_teacher)
      review_date = create(:iep_review_date, iep: plan, review_date: Date.current)

      identification = described_class.build(plan, classroom: classroom)['identification']

      expect(identification['student_id']).to eq(plan.student_id)
      expect(identification['unity_id']).to eq(unity.id)
      expect(identification['classroom_id']).to eq(classroom.id)
      expect(identification['teacher_api_code']).to eq(regent.api_code)
      expect(identification['teacher_id']).to eq(regent.id)
      expect(identification['aee_teacher_id']).to eq(plan.aee_teacher_id)
      expect(identification['review_date_ids']).to eq([review_date.id])
    end

    # include (e não be_nil) para a asserção falhar também quando a chave não existe: um erro de
    # digitação no nome passaria batido, já que nenhum leitor consome estes ids.
    it 'leaves the context ids empty when the plan is opened without a classroom' do
      plan = create(:individualized_educational_plan)

      identification = described_class.build(plan, student_data: {})['identification']

      expect(identification).to include('unity_id' => nil, 'classroom_id' => nil,
                                        'teacher_id' => nil, 'teacher_api_code' => nil)
    end

    # Turma com regente cadastrado no i-Educar cujo Teacher ainda não sincronizou: id e nome saem
    # vazios, e só o api_code preserva que existe regente.
    it 'keeps the regent api code when the teacher has not been synced yet' do
      classroom = create(:classroom, regent_api_code: 'regente-sem-professor')
      plan = create(:individualized_educational_plan)

      identification = described_class.build(plan, student_data: {}, classroom: classroom)['identification']

      expect(identification['teacher_api_code']).to eq('regente-sem-professor')
      expect(identification).to include('teacher_id' => nil, 'teacher_name' => nil)
    end

    # O Restorer remonta as linhas das seções 4/5 casando revisão por POSIÇÃO, então as duas
    # arrays têm de concordar índice a índice na ordem cronológica.
    it 'keeps the review date ids aligned with the dates in chronological order' do
      plan = create(:individualized_educational_plan)
      later = create(:iep_review_date, iep: plan, review_date: Date.current + 30)
      earlier = create(:iep_review_date, iep: plan, review_date: Date.current + 10)

      identification = described_class.build(plan, student_data: {})['identification']

      expect(identification['review_dates']).to eq([earlier.review_date, later.review_date])
      expect(identification['review_date_ids']).to eq([earlier.id, later.id])
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

    # Duas opções na mesma categoria: com uma só, um filtro a mais de um dos lados manteria o
    # exemplo verde e o desalinhamento entre descrição e id ficaria congelado no documento.
    it 'pairs every description with the id of the same option' do
      plan = create(:individualized_educational_plan)
      verbal = create(:iep_option, :communication_profile, description: 'Verbal')
      signed = create(:iep_option, :communication_profile, description: 'Sinalizada')
      create(:iep_selected_option, iep: plan, iep_option: verbal)
      create(:iep_selected_option, iep: plan, iep_option: signed)

      characterization = described_class.build(plan, student_data: {})['characterization']

      pairs = characterization['communication_profile'].zip(characterization['communication_profile_option_ids'])
      expect(pairs).to match_array([['Verbal', verbal.id], ['Sinalizada', signed.id]])
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

    # false é resposta ("Não"), não ausência: precisa sobreviver ao slice — um consumidor que
    # use present? no lugar de nil? faria o "Não" sumir do documento. A ida e volta pelo jsonb
    # é provada no spec de round-trip, não aqui (este exemplo fica em memória).
    it 'freezes the medication and family environment fields keeping a "no" answer' do
      plan = create(:individualized_educational_plan,
                    uses_medication: false, medication_name: 'Medicamento A',
                    medication_dosage: '5mg', medication_schedule: '08:00',
                    medication_notes: 'Apos o almoco',
                    family_environment_characteristics: 'Rotina estruturada')

      support_team = described_class.build(plan, student_data: {})['support_team']

      expect(support_team['uses_medication']).to eq(false)
      expect(support_team['medication_name']).to eq('Medicamento A')
      expect(support_team['medication_dosage']).to eq('5mg')
      expect(support_team['medication_schedule']).to eq('08:00')
      expect(support_team['medication_notes']).to eq('Apos o almoco')
      expect(support_team['family_environment_characteristics']).to eq('Rotina estruturada')
    end

    # O id gravado é o da OPÇÃO, não o da linha de junção. As junções descartáveis abaixo afastam
    # as duas sequences: com os ids coincidindo por acaso, o exemplo não distinguiria os dois.
    it 'records the option id and not the id of the join row' do
      plan = create(:individualized_educational_plan)
      shared = create(:iep_option, :communication_profile)
      create_list(:iep_selected_option, 3, iep_option: shared)
      option = create(:iep_option, :communication_profile, description: 'Verbal')
      join_row = create(:iep_selected_option, iep: plan, iep_option: option)

      expect(join_row.id).not_to eq(option.id)

      characterization = described_class.build(plan, student_data: {})['characterization']

      expect(characterization['communication_profile_option_ids']).to eq([option.id])
      expect(characterization['communication_profile_option_ids']).not_to include(join_row.id)
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

      expect(line['iep_curricular_planning_id']).to eq(planning.id)
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

      expect(line['iep_periodic_evaluation_id']).to eq(evaluation.id)
      expect(line['knowledge_area_id']).to eq(knowledge_area.id)
      expect(line['discipline_id']).to be_nil
    end
  end
end
