require 'rails_helper'

# Renderiza o formulário do PEID (wizard de 6 seções) sem o layout, garantindo que o ERB
# não estoura. Serve de rede para os refactors das views (evita quebra silenciosa, já que
# specs de controller não renderizam as views).
RSpec.describe 'individualized_educational_plans/_form', type: :view do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  def assign_form_options(plan)
    assign(:individualized_educational_plan, plan)
    assign(:students, Student.where(id: plan.student_id))
    assign(:aee_teachers, Teacher.none)
    assign(:disciplines, Discipline.where(id: plan.iep_curricular_plannings.map(&:discipline_id).compact))
    assign(:knowledge_areas, KnowledgeArea.none)
    assign(:iep_options_by_kind, IepOption.enabled.ordered.group_by(&:kind))
  end

  it 'renders the wizard of a new plan without raising' do
    plan = build(:individualized_educational_plan)
    3.times { plan.iep_review_dates.build }
    assign_form_options(plan)

    expect { render partial: 'individualized_educational_plans/form' }.not_to raise_error
    expect(rendered).to include('id="pei-wizard"')
    expect(rendered).not_to include('translation_missing')
  end

  it 'renders an existing plan with sections 4 and 5 filled without raising' do
    plan = create(:individualized_educational_plan)
    review = create(:iep_review_date, iep: plan)
    create(:iep_curricular_planning, iep: plan, iep_review_date: review, long_term_goal: 'Meta')
    create(:iep_periodic_evaluation, iep: plan, iep_review_date: review, acquired_skills: 'Habilidades')
    assign_form_options(plan.reload)

    expect { render partial: 'individualized_educational_plans/form' }.not_to raise_error
    expect(rendered).to include('iep-component-panel')
    expect(rendered).not_to include('translation_missing')
  end

  # Modo leitura (view_only): mesmo formulário, sem controles de edição.
  context 'in view_only mode' do
    it 'renders read-only without edit controls and blocks submit' do
      plan = create(:individualized_educational_plan)
      review = create(:iep_review_date, iep: plan)
      create(:iep_curricular_planning, iep: plan, iep_review_date: review, long_term_goal: 'Meta')
      assign_form_options(plan.reload)

      expect do
        render partial: 'individualized_educational_plans/form', locals: { view_only: true }
      end.not_to raise_error

      expect(rendered).to include('id="pei-wizard"')
      expect(rendered).not_to include('translation_missing')
      # Bloqueia submit e não exibe os controles de edição/finalização.
      expect(rendered).to include('onsubmit="return false;"')
      expect(rendered).not_to include('pei-wizard-finish')
      expect(rendered).not_to include('iep-finalize-modal')
      expect(rendered).not_to include('iep-add-component')
    end
  end
end
