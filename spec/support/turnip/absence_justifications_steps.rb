# encoding: utf-8
module Turnip
  module AbsenceJustificationsSteps
    step "que acesso a listagem de justificativas de faltas" do
      # click_menu 'Frequência > Justificativas de falta'
    end

    step 'eu acesso a tela de listagem de justificativas de falta' do
      # click_menu 'Frequência > Justificativas de falta'
    end

    step 'eu entrar no formulário de nova justificativa de falta' do
      # click_on "Nova justificativa de falta"
    end

    step 'poderei cadastrar uma nova justificativa de falta' do
      # TODO:
      # fill_mask "Data inicial", with: '15/02/2015'
      # fill_mask "Data final", with: '15/02/2015'
      # fill_autocomplete 'Aluno', with: 'Bruce Wayne'
      # fill_in "Justificativa", with: "Cras justo odio, dapibus ac facilisis in, egestas eget quam."
      #
      # click_on "Salvar"
      #
      # wait_for(page).to have_content "Justificativa de falta foi criada com sucesso."
    end

    step 'que existe uma justificativa de falta cadastrada para o usuário logado' do
      # TODO:
      # current_user = users(:john_doe)
      # @absence_justification = create(:absence_justification, author: current_user)

      # click_menu 'Frequência > Justificativas de falta'
      #
      # within :xpath, '//table/tbody/tr[last()]' do
      #   wait_for(page).to have_content(@absence_justification.localized.absence_date)
      # end
    end

    step 'que existe uma justificativa de falta cadastrada para outro usuário' do
      # TODO:
      # @another_user_absence_justification = create(:absence_justification)
    end

    step 'entro na tela de edição desta justificativa de falta' do
      # TODO:
      # within :xpath, '//table/tbody/tr[last()]' do
      #   click_on 'Editar'
      # end
    end

    step 'poderei alterar os dados desta justificativa de falta' do
      # TODO:
      # fill_mask 'Data inicial', with: '20/01/2015'
      #
      # click_on 'Salvar'
      #
      # wait_for(page).to have_content 'Justificativa de falta foi alterada com sucesso.'
      #
      # within :xpath, '//table/tbody/tr[last()]' do
      #   wait_for(page).to have_content '20/01/2015'
      # end
    end

    step "poderei excluir uma justificativa de falta" do
      # TODO:
      # within :xpath, '//table/tbody/tr[last()]' do
      #   wait_for(page).to have_content(@absence_justification.localized.absence_date)
      #   click_on 'Excluir'
      # end
      #
      # wait_for(page).to have_content "Justificativa de falta foi apagada com sucesso"
      #
      # wait_for(page).to have_no_content "02/01/2015"
    end

    step 'devo visualizar minha justificativa de falta' do
      # TODO:
      # wait_for(page).to have_content(@absence_justification.student.name)
    end

    step 'não devo visualizar a justificativa de falta de outro usuário' do
      # TODO:
      # wait_for(page).to_not have_content(@another_user_absence_justification.student.name)
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::AbsenceJustificationsSteps
end
