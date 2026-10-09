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

  def textarea_placeholders
    Nokogiri::HTML.fragment(rendered).css('textarea').map { |field| field['placeholder'] }.compact
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

  # Tri-state de medicação: as 3 opções (em branco/Sim/Não) selecionáveis na edição. Passar
  # :disabled junto da collection desabilitaria a OPTION de value correspondente — é a regressão
  # que a asserção de "nenhuma option disabled" pega.
  it 'renders the medication select with the three states selectable and the stored answer chosen' do
    plan = build(:individualized_educational_plan, uses_medication: false)
    3.times { plan.iep_review_dates.build }
    assign_form_options(plan)

    render partial: 'individualized_educational_plans/form'

    select_html = rendered[%r{<select[^>]*uses_medication[^>]*>.*?</select>}m]
    expect(select_html).to include('<option value=""></option>')
    expect(select_html).to include('<option value="true">Sim</option>')
    expect(select_html).to include('<option selected="selected" value="false">Não</option>')
    expect(select_html).not_to include('disabled')
  end

  def medications_block
    Nokogiri::HTML.fragment(rendered).at_css('#iep-medications-block')
  end

  it 'hides the medication list unless the answer is "yes"' do
    plan = build(:individualized_educational_plan, uses_medication: false)
    assign_form_options(plan)

    render partial: 'individualized_educational_plans/form'

    expect(medications_block['class']).to include('hidden')
    expect(medications_block.at_css('.iep-add-medication')).to be_present
  end

  it 'renders one row per medication, in order, with the remove button' do
    plan = create(:individualized_educational_plan, uses_medication: true,
                                                    iep_medications_attributes: [{ name: 'Metilfenidato' },
                                                                                 { name: 'Risperidona' }])
    assign_form_options(plan.reload)

    render partial: 'individualized_educational_plans/form'

    rows = medications_block.css('.iep-medication-row')
    expect(medications_block['class']).not_to include('hidden')
    expect(rows.map { |row| row.at_css('input[name$="[name]"]')['value'] }).to eq(%w[Metilfenidato Risperidona])
    expect(rows.map { |row| row.at_css('.remove_fields') }).to all(be_present)
    expect(rendered).not_to include('translation_missing')
  end

  it 'shows the filling instructions as placeholders while editing' do
    plan = build(:individualized_educational_plan)
    3.times { plan.iep_review_dates.build }
    assign_form_options(plan)

    render partial: 'individualized_educational_plans/form'

    expect(textarea_placeholders)
      .to include(I18n.t('individualized_educational_plans.section_characterization.characterization_placeholder'))
  end

  # Modo leitura (view_only): mesmo formulário, sem controles de edição.
  def wizard
    Nokogiri::HTML.fragment(rendered).at_css('#pei-wizard')
  end

  describe 'draft autosave' do
    it 'turns the autosave on while editing and offers the shortcut to section 1 without review dates' do
      plan = create(:individualized_educational_plan)
      assign_form_options(plan)

      render partial: 'individualized_educational_plans/form'

      expect(wizard['data-autosave']).to eq('on')
      expect(wizard['data-draft-unavailable']).to eq('off')
      expect(wizard.at_css('.iep-locked-notice')).to be_present
      expect(wizard.at_css('.iep-save-error .iep-save-error-text')).to be_present
      expect(wizard.css('#pei-step-4 .iep-go-to-identification').size).to eq(1)
      expect(rendered).to include(I18n.t('individualized_educational_plans.form.no_reviews_hint'))
    end

    it 'flags the draft as unavailable and warns when it does not apply to the student' do
      plan = build(:individualized_educational_plan)
      assign_form_options(plan)
      assign(:draft_unavailable, true)

      render partial: 'individualized_educational_plans/form'

      expect(wizard['data-autosave']).to eq('on')
      expect(wizard['data-draft-unavailable']).to eq('on')
      expect(wizard.at_css('.iep-no-draft-notice')['style']).not_to include('display: none')
    end

    # O professor não altera a seção 1: o atalho para ela não faz sentido no escopo de componente.
    it 'hides the shortcut to section 1 for a teacher restricted to the own components' do
      plan = create(:individualized_educational_plan)
      assign_form_options(plan)
      assign(:editable_component_scope, double(owns_line?: false))

      render partial: 'individualized_educational_plans/form'

      expect(wizard.css('#pei-step-4 .iep-go-to-identification')).to be_empty
    end

    it 'turns the autosave off in view_only mode' do
      plan = create(:individualized_educational_plan)
      assign_form_options(plan)

      render partial: 'individualized_educational_plans/form', locals: { view_only: true }

      expect(wizard['data-autosave']).to eq('off')
      expect(wizard.at_css('.iep-locked-notice')).to be_nil
      expect(wizard.at_css('.iep-save-error')).to be_nil
      expect(rendered).not_to include('iep-save-status-text')
    end
  end

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
      # Em leitura o select de medicação inteiro fica desabilitado (o submit já é bloqueado).
      expect(rendered[%r{<select[^>]*uses_medication[^>]*>}]).to include('disabled')
    end

    it 'hides the medications of a plan answered "no"' do
      plan = create(:individualized_educational_plan, uses_medication: false)
      create(:iep_medication, iep: plan)
      assign_form_options(plan.reload)

      render partial: 'individualized_educational_plans/form', locals: { view_only: true }

      expect(medications_block['class']).to include('hidden')
    end

    it 'lists the medications read-only, without add or remove buttons' do
      plan = create(:individualized_educational_plan, uses_medication: true,
                                                      iep_medications_attributes: [{ name: 'Metilfenidato' }])
      assign_form_options(plan.reload)

      render partial: 'individualized_educational_plans/form', locals: { view_only: true }

      expect(medications_block.at_css('input[name$="[name]"]')['readonly']).to be_present
      expect(medications_block.at_css('.remove_fields, .iep-add-medication')).to be_nil
      expect(rendered).not_to include('iep-medications-discard-modal')
    end

    # Placeholder é instrução de preenchimento: em leitura passaria por resposta do usuário.
    it 'drops the placeholders so an unfilled field shows as empty' do
      plan = create(:individualized_educational_plan)
      assign_form_options(plan.reload)

      render partial: 'individualized_educational_plans/form', locals: { view_only: true }

      expect(textarea_placeholders).to be_empty
    end
  end

  # Tela de versão publicada: o MESMO form é alimentado pelo Result do restorer — plano NÃO salvo,
  # ids sintéticos e coleções como Array. Combinação que só a versão exercita.
  context 'rendering a restored version snapshot' do
    let(:content) do
      {
        'identification' => {
          'student_name' => 'Aluno Congelado', 'guardians' => nil, 'guardians_unavailable' => true,
          'year' => 2026, 'review_dates' => ['2026-04-01']
        },
        'characterization' => { 'characterization' => 'Perfil congelado',
                                'communication_profile' => ['Comunicação verbal'] },
        'curricular_plannings' => [
          { 'review_number' => 1, 'component_type' => 'discipline',
            'component_name' => 'Matemática', 'long_term_goal' => 'Meta congelada',
            'instructional_accommodations' => ['Materiais concretos'],
            'environmental_accommodations' => [], 'assessment_accommodations' => [] }
        ]
      }
    end

    before do
      restored = IndividualizedEducationalPlanSnapshotRestorer.restore(content)
      assign(:individualized_educational_plan, restored.plan)
      assign(:students, restored.students)
      assign(:aee_teachers, restored.aee_teachers)
      assign(:iep_options_by_kind, restored.iep_options_by_kind)
      assign(:disciplines, [])
      assign(:knowledge_areas, [])
    end

    it 'renders the reconstructed version and shows the frozen values with student fetch off' do
      expect do
        render partial: 'individualized_educational_plans/form',
               locals: { view_only: true, student_fetch: false }
      end.not_to raise_error

      expect(rendered).to include('Aluno Congelado')
      expect(rendered).to include('Perfil congelado')
      expect(rendered).to include('Meta congelada')
      expect(rendered).to include('data-student-fetch="off"')
      expect(rendered).not_to include('translation_missing')
    end

    # O plano da versão é um stand-in sem id: sem o local, o data attribute sai vazio e a tela
    # deixa de buscar os laudos — que, ao contrário do resto, não são congelados no snapshot.
    it 'carries the id of the origin plan so the medical reports are still fetched' do
      render partial: 'individualized_educational_plans/form',
             locals: { view_only: true, student_fetch: false, medical_reports_plan_id: 42 }

      expect(rendered).to include('data-medical-reports-plan-id="42"')
    end

    it 'shows the guardians-unavailable warning frozen from the snapshot (not hidden)' do
      render partial: 'individualized_educational_plans/form',
             locals: { view_only: true, student_fetch: false }

      # A flag congelada como indisponível → o aviso é renderizado sem display:none pelo servidor.
      expect(rendered).not_to match(/iep-guardians-warning"[^>]*display: none/)
    end
  end
end
