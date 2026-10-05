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
        %w[family_guidelines medication_notes family_environment_characteristics
           external_professionals_guidelines],
        'accompaniment' => ['Psicólogo'], 'support_type' => ['AEE'], 'uses_medication' => true,
        'medications' => [{ 'name' => 'Metilfenidato', 'dosage' => '10 mg', 'schedule' => '07h30' }]
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
      'medications' => [{ 'name' => 'MED-NOME', 'dosage' => 'MED-DOSE', 'schedule' => 'MED-HORARIO' }],
      'medication_notes' => 'MED-OBS',
      'family_environment_characteristics' => 'AMBIENTE-FAM',
      'external_professionals_guidelines' => 'PROF-EXT'
    )

    positions = %w[ORIENTACOES-FAM Sim MED-NOME MED-DOSE MED-HORARIO
                   MED-OBS AMBIENTE-FAM PROF-EXT].map { |token| section.index(token) }

    expect(positions).to all(be_an(Integer))
    expect(positions).to eq(positions.sort)
  end

  it 'lists every medication in a name, dosage and schedule table' do
    section = support_section(
      'uses_medication' => true,
      'medications' => [
        { 'name' => 'Metilfenidato', 'dosage' => '10 mg', 'schedule' => '07h30' },
        { 'name' => 'Risperidona', 'dosage' => nil, 'schedule' => '20h00' }
      ]
    )

    rows = Nokogiri::HTML.fragment(section).css('table.medications-table tr')
      .map { |row| row.css('th, td').map { |cell| cell.text.strip } }

    expect(rows).to eq([
      %w[Nome\ do\ medicamento Dosagem Horário],
      %w[Metilfenidato 10\ mg 07h30],
      %w[Risperidona - 20h00]
    ])
  end

  # Versão publicada com o campo único e a pergunta em branco: o medicamento continua impresso.
  it 'prints the single medication of an older snapshot as one table row' do
    section = support_section('medication_name' => 'Medicamento A', 'medication_dosage' => '5mg')

    rows = Nokogiri::HTML.fragment(section).css('table.medications-table tr')
    expect(rows.last.css('td').map { |cell| cell.text.strip }).to eq(['Medicamento A', '5mg', '-'])
    expect(section).not_to include(empty_message)
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

    field_cells = Nokogiri::HTML.fragment(rendered).css('td').select { |cell| cell.at_css('p, ul, table') }
    unwrapped = field_cells.reject { |cell| cell['class'] == 'field-cell' && cell.at_css('> div.field') }

    expect(field_cells.count).to eq(24)
    expect(unwrapped).to be_empty
  end

  # O comportamento na quebra de página é metade markup (aqui) e metade CSS (no layout), e o
  # render de partial não carrega layout — sem este guarda, renomear uma classe ou remover uma
  # das regras de quebra deixa a suíte verde e o PDF regride em silêncio.
  it 'backs every class of the partial with a rule in the pdf layout' do
    presenter = IndividualizedEducationalPlanReportPresenter.from_snapshot(filled_snapshot)
    render partial: 'individualized_educational_plans/pdf_content', locals: { presenter: presenter }

    used = Nokogiri::HTML.fragment(rendered).css('[class]').flat_map { |node| node['class'].split }.uniq

    expect(used).to include('continuation-rule', 'field-cell', 'field', 'section-title', 'field-label')
    # (?![\w-]) evita que a regra .field-cell sirva de fiadora para a classe field.
    expect(used.reject { |name| pdf_layout.match?(/\.#{Regexp.escape(name)}(?![\w-])/) }).to be_empty
  end

  # As três regras que sustentam a correção da quebra de página: fechar a caixa no fim da página,
  # manter o valor junto do seu rótulo e impedir que o título fique sozinho no rodapé.
  it 'declares the three page-break rules the pdf layout depends on' do
    # Recorta o bloco da regra para que renomear .field não passe pelo seletor .field .field-label,
    # e ancora no início da linha para que a versão -webkit- não responda pela não prefixada.
    field_rule = pdf_layout[/^\s*\.field \{(.*?)\}/m, 1].to_s

    expect(field_rule).to match(/^\s*-webkit-box-decoration-break: clone;/)
    expect(field_rule).to match(/^\s*box-decoration-break: clone;/)
    expect(pdf_layout).to match(/\.field \.field-label \+ p,\s*\.field \.field-label \+ ul \{[^}]*break-before: avoid/m)
    expect(pdf_layout).to match(/\.section-title \{[^}]*break-after: avoid/m)
  end

  def pdf_layout
    Rails.root.join('app/views/layouts/pdf_individualized_educational_plan.html.erb').read
  end
end
