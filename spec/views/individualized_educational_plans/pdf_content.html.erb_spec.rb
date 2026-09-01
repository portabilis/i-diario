require 'rails_helper'

# Renderiza o conteúdo do PDF a partir de um snapshot puro (Presenter.from_snapshot), sem tocar o
# banco — o mesmo caminho da versão publicada. É o único lugar que exercita a seção 3 com o
# tri-state de medicação: false ("Não") imprime, nil (não respondido) some.
RSpec.describe 'individualized_educational_plans/_pdf_content', type: :view do
  let(:empty_message) { I18n.t('individualized_educational_plans.pdf.empty_message') }

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
end
