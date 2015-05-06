# encoding: utf-8
module Turnip
  module AbsenceJustificationsSteps
    step "que acesso a listagem de justificativas de faltas" do
      click_***REMOVED*** 'Frequência > Justificativas de falta'
    end

    step 'eu entrar no formulário de nova justificativa de falta' do
      click_on "Nova justificativa de falta"
    end

    step 'poderei cadastrar uma nova justificativa de falta' do
      fill_mask "Data", with: '15/02/2015'
      fill_autocomplete 'Aluno', with: 'Bruce Wayne'
      fill_in "Justificativa", with: "Cras justo odio, dapibus ac facilisis in, egestas eget quam."

      click_on "Salvar"

      expect(page).to have_content "Justificativa de falta foi criada com sucesso."
    end

    step 'que existe uma justificativa de falta cadastrada' do
      click_***REMOVED*** 'Frequência > Justificativas de falta'

      within :xpath, '//table/tbody/tr[last()]' do
        expect(page).to have_content "02/01/2015"
      end
    end

    step 'entro na tela de edição desta justificativa de falta' do
      within :xpath, '//table/tbody/tr[last()]' do
        click_on 'Editar'
      end
    end

    step 'poderei alterar os dados desta justificativa de falta' do
      fill_mask 'Data', with: '20/01/2015'

      click_on 'Salvar'

      expect(page).to have_content 'Justificativa de falta foi alterada com sucesso.'

      within :xpath, '//table/tbody/tr[last()]' do
        expect(page).to have_content '20/01/2015'
      end
    end

    step "poderei excluir uma justificativa de falta" do
      within :xpath, '//table/tbody/tr[last()]' do
        expect(page).to have_content "02/01/2015"
        click_on 'Excluir'
      end

      expect(page).to have_content "Justificativa de falta foi apagada com sucesso"

      expect(page).to have_no_content "02/01/2015"
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::AbsenceJustificationsSteps
end
