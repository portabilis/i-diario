require 'rails_helper'

# Renderiza o conteúdo do PDF a partir de um snapshot puro (Presenter.from_snapshot), sem tocar o
# banco — o mesmo caminho da versão publicada. É o único lugar que exercita a seção 3 com o
# tri-state de medicação: false ("Não") imprime, nil (não respondido) some.
RSpec.describe 'individualized_educational_plans/_pdf_content', type: :view do
  let(:empty_message) { I18n.t('individualized_educational_plans.pdf.empty_message') }

  # Snapshot com todas as seções preenchidas, para conferir a estrutura das células de campo.
  let(:filled_snapshot) do
    review = { 'review_number' => 1, 'review_date' => '2026-03-01', 'component_name' => 'Disciplina' }

    {
      'characterization' => filled_fields(
        %w[characterization clinical_diagnosis_justification school_history potentialities difficulties
           preferences_interests effective_strategies],
        'communication_profile' => ['Comunicação funcional'],
        'social_interaction_profile' => ['Atividades solitárias'], 'autonomy' => ['Independente']
      ),
      'support_team' => filled_fields(
        %w[family_guidelines medication_name medication_dosage medication_schedule medication_notes
           family_environment_characteristics external_professionals_guidelines],
        'accompaniment' => ['Psicólogo'], 'support_type' => ['AEE'], 'uses_medication' => true
      ),
      'curricular_plannings' => [
        review.merge(filled_fields(%w[long_term_goal stage_objectives skills_to_develop methodologies],
                                   'instructional_accommodations' => ['Materiais concretos']))
      ],
      'periodic_evaluations' => [
        review.merge(filled_fields(%w[acquired_skills in_progress_skills not_acquired_skills period_report
                                      next_stage_adjustments]))
      ],
      'final_evaluation' => filled_fields(%w[annual_report overall_evolution next_year_recommendations
                                             referrals_made])
    }
  end

  # Preenche os campos de texto com o mesmo conteúdo, ao lado dos campos de lista informados.
  def filled_fields(text_fields, list_fields = {})
    text_fields.each_with_object(list_fields.dup) { |field, content| content[field] = 'Texto do campo' }
  end

  def support_section(support_team)
    presenter = IndividualizedEducationalPlanReportPresenter.from_snapshot('support_team' => support_team)
    render partial: 'individualized_educational_plans/pdf_content', locals: { presenter: presenter }
    # Recorta a tabela da seção 3 (do título "3. ..." até a próxima tabela).
    rendered.split('3. ')[1].split('<table>').first
  end

  it 'prints "Não" and keeps the section when the medication answer is the only content' do
    section = support_section('uses_medication' => false)

    expect(section).to include('Faz uso de medicação?')
    expect(section).to include('Não')
    expect(section).not_to include(empty_message)
  end

  it 'omits the medication question when it was not answered' do
    section = support_section('family_guidelines' => 'Orientações da família preenchidas')

    expect(section).not_to include('Faz uso de medicação?')
    expect(section).to include('Orientações da família preenchidas')
  end

  it 'shows the empty message when the support team section has no content' do
    section = support_section({})

    expect(section).to include(empty_message)
  end

  it 'prints the fields in the same order as the form' do
    section = support_section(
      'family_guidelines' => 'ORIENTACOES-FAM', 'uses_medication' => true,
      'medication_name' => 'MED-NOME', 'medication_dosage' => 'MED-DOSE',
      'medication_schedule' => 'MED-HORARIO', 'medication_notes' => 'MED-OBS',
      'family_environment_characteristics' => 'AMBIENTE-FAM',
      'external_professionals_guidelines' => 'PROF-EXT'
    )

    positions = %w[ORIENTACOES-FAM Sim MED-NOME MED-DOSE MED-HORARIO
                   MED-OBS AMBIENTE-FAM PROF-EXT].map { |token| section.index(token) }

    expect(positions).to all(be_an(Integer))
    expect(positions).to eq(positions.sort)
  end

  # O <thead> de cada seção carrega só a régua de continuação. Título dentro dele volta a ser
  # reimpresso a cada página, e sem a régua a continuação abre sem a linha de fechamento.
  it 'keeps only the continuation rule in each section header' do
    presenter = IndividualizedEducationalPlanReportPresenter.from_snapshot(filled_snapshot)
    render partial: 'individualized_educational_plans/pdf_content', locals: { presenter: presenter }

    document = Nokogiri::HTML.fragment(rendered)

    expect(document.css('thead').map { |head| head.css('tr').map { |row| row['class'] } })
      .to eq([['continuation-rule']] * 6)
    expect(document.css('thead .section-title')).to be_empty
    expect(document.css('tbody .section-title').count).to eq(6)
  end

  # Todo campo de texto ou lista fica dentro do wrapper .field: é ele que o Chrome fragmenta na
  # quebra de página — fecha a caixa no fim da página e afasta a continuação da margem superior
  # da seguinte. Campo novo direto na célula volta a quebrar colado na margem.
  it 'wraps every text or list field in the fragmentable .field element' do
    presenter = IndividualizedEducationalPlanReportPresenter.from_snapshot(filled_snapshot)
    render partial: 'individualized_educational_plans/pdf_content', locals: { presenter: presenter }

    field_cells = Nokogiri::HTML.fragment(rendered).css('td').select { |cell| cell.at_css('p, ul') }
    unwrapped = field_cells.reject { |cell| cell['class'] == 'field-cell' && cell.at_css('> div.field') }

    expect(field_cells.count).to eq(26)
    expect(unwrapped).to be_empty
  end
end
