require 'rails_helper'

# Escopo de edição do professor: só as seções 4/5 do componente que ele leciona na turma
# do plano (disciplina) ou da área de conhecimento dessas disciplinas.
RSpec.describe IndividualizedEducationalPlanTeacherScope, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  let(:teacher) { create(:teacher) }
  let(:classroom) { create(:classroom, year: Date.current.year) }
  let(:knowledge_area) { create(:knowledge_area) }
  let(:own_discipline) { create(:discipline, knowledge_area: knowledge_area) }
  let(:other_discipline) { create(:discipline) }
  let(:plan) { create(:individualized_educational_plan, classroom: classroom) }

  subject(:scope) { described_class.new(teacher, plan) }

  before do
    create(:teacher_discipline_classroom, teacher: teacher, classroom: classroom,
                                          discipline: own_discipline, year: Date.current.year)
  end

  it 'returns only the components the teacher teaches in the plan classroom' do
    expect(scope.disciplines.map(&:id)).to contain_exactly(own_discipline.id)
    expect(scope.knowledge_areas.map(&:id)).to contain_exactly(knowledge_area.id)
  end

  describe '#owns?' do
    it 'matches by discipline or by knowledge area and rejects others' do
      expect(scope.owns?(own_discipline.id, nil)).to eq(true)
      expect(scope.owns?(nil, knowledge_area.id)).to eq(true)
      expect(scope.owns?(other_discipline.id, nil)).to eq(false)
      expect(scope.owns?(nil, nil)).to eq(false)
    end
  end

  describe '#touched_lines_authorized?' do
    it 'is true when only own-component lines were changed' do
      line = create(:iep_curricular_planning, iep: plan, discipline: own_discipline, long_term_goal: 'Meta')
      plan.reload
      plan.iep_curricular_plannings.detect { |row| row.id == line.id }.long_term_goal = 'Nova meta'

      expect(scope.touched_lines_authorized?).to eq(true)
    end

    it 'is false when a line of another component was changed' do
      line = create(:iep_curricular_planning, iep: plan, discipline: other_discipline, long_term_goal: 'De outro')
      plan.reload
      plan.iep_curricular_plannings.detect { |row| row.id == line.id }.long_term_goal = 'Invadido'

      expect(scope.touched_lines_authorized?).to eq(false)
    end

    it 'ignores untouched lines of other components' do
      create(:iep_curricular_planning, iep: plan, discipline: other_discipline)
      plan.reload

      expect(scope.touched_lines_authorized?).to eq(true)
    end

    it 'ignores round-trip-only changes on other lines (nil/"" and the browser \r\n)' do
      other = create(:iep_curricular_planning, iep: plan, discipline: other_discipline,
                                               long_term_goal: "linha1\nlinha2", stage_objectives: nil)
      plan.reload
      row = plan.iep_curricular_plannings.detect { |r| r.id == other.id }
      # o navegador reenvia a linha alheia (readonly) com \r\n e "" no lugar de nil
      row.long_term_goal = "linha1\r\nlinha2"
      row.stage_objectives = ''

      expect(scope.touched_lines_authorized?).to eq(true)
    end

    # Troca de componente (defesa do discipline_id_was)
    it 'blocks reassigning another component line to the teacher discipline' do
      line = create(:iep_curricular_planning, iep: plan, discipline: other_discipline, long_term_goal: 'De outro')
      plan.reload
      plan.iep_curricular_plannings.detect { |r| r.id == line.id }.discipline_id = own_discipline.id

      expect(scope.touched_lines_authorized?).to eq(false)
    end

    it 'blocks reassigning the own line to another discipline' do
      line = create(:iep_curricular_planning, iep: plan, discipline: own_discipline, long_term_goal: 'Minha')
      plan.reload
      plan.iep_curricular_plannings.detect { |r| r.id == line.id }.discipline_id = other_discipline.id

      expect(scope.touched_lines_authorized?).to eq(false)
    end

    # Edição só de acomodações (options_touched?)
    it 'blocks changing only the accommodations of another component line' do
      line = create(:iep_curricular_planning, iep: plan, discipline: other_discipline, long_term_goal: 'De outro')
      plan.reload
      plan.iep_curricular_plannings.detect { |r| r.id == line.id }
          .iep_curricular_planning_options.build(iep_option: create(:iep_option, :instructional_accommodation))

      expect(scope.touched_lines_authorized?).to eq(false)
    end

    # Seção 5 (avaliações periódicas)
    it 'checks section 5 (periodic evaluations) lines too' do
      line = create(:iep_periodic_evaluation, iep: plan, discipline: other_discipline, acquired_skills: 'De outro')
      plan.reload
      plan.iep_periodic_evaluations.detect { |r| r.id == line.id }.acquired_skills = 'Invadido'

      expect(scope.touched_lines_authorized?).to eq(false)
    end

    it 'allows changing the own section 5 line' do
      line = create(:iep_periodic_evaluation, iep: plan, discipline: own_discipline, acquired_skills: 'Minha')
      plan.reload
      plan.iep_periodic_evaluations.detect { |r| r.id == line.id }.acquired_skills = 'Atualizada'

      expect(scope.touched_lines_authorized?).to eq(true)
    end

    # Adicionar linha (new_record) e excluir (_destroy)
    it 'allows adding a new line in the own component' do
      plan.iep_curricular_plannings.build(discipline: own_discipline, long_term_goal: 'Nova')

      expect(scope.touched_lines_authorized?).to eq(true)
    end

    it 'blocks adding a new line in another component' do
      plan.iep_curricular_plannings.build(discipline: other_discipline, long_term_goal: 'Nova')

      expect(scope.touched_lines_authorized?).to eq(false)
    end

    it 'blocks destroying another component line' do
      line = create(:iep_curricular_planning, iep: plan, discipline: other_discipline, long_term_goal: 'De outro')
      plan.reload
      plan.iep_curricular_plannings.detect { |r| r.id == line.id }.mark_for_destruction

      expect(scope.touched_lines_authorized?).to eq(false)
    end
  end
end
