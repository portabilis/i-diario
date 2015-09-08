# encoding: utf-8
module Turnip
  module SchoolCalendarSteps
    step 'que acesso a listagem de celendários letivos' do
      click_***REMOVED*** 'Calendário letivo'
    end

    step 'eu clicar em Sincronizar' do
      click_on 'Sincronizar'
    end

    step 'poderei sincronizar novos calendários letivos do i-Educar' do

    end

    step 'que acesso a listagem de calendário letivo' do
      click_***REMOVED*** 'Calendário letivo'
    end

    step 'eu entrar no formulário de novo calendário letivo' do
      click_on "Novo calendário"
    end

    step 'poderei cadastrar um novo calendário letivo' do
      fill_in 'Ano', with: '2010'
      fill_in 'Número de aulas por turno', with: '4'

      click_link "Adicionar etapa"

      within '#school-calendar-steps tr:last-child' do
        fill_mask 'Data inicial', with: '01/01/2010'
        fill_mask 'Data final', with: '01/03/2010'
        fill_mask 'Data inicial para postagem', with: '15/02/2010'
        fill_mask 'Data final para postagem', with: '01/03/2010'
      end

      click_on 'Salvar'

      expect(page).to have_content 'Calendário letivo foi criado com sucesso.'
    end

    step 'que existe um calendário letivo cadastrada' do
      click_***REMOVED*** 'Calendário letivo'

      within '#resources > tbody > tr:nth-child(1)' do
        expect(page).to have_content "2015"
      end
    end

    step 'entro na tela de edição deste calendário letivo' do
      within '#resources > tbody > tr:nth-child(1)' do
        click_on 'Editar'
      end
    end

    step 'poderei alterar os dados deste calendário letivo' do
      fill_in 'Número de aulas por turno', with: '3'

      click_on 'Salvar'

      expect(page).to have_content 'Calendário letivo foi alterado com sucesso.'
      expect(page).to have_content '3'
    end

    step 'poderei excluir um calendário letivo' do
      within '#resources > tbody > tr:nth-child(1)' do
        expect(page).to have_content "2015"
        click_link "Excluir"
      end

      expect(page).to have_content 'Calendário letivo foi apagado com sucesso'

      within '#resources > tbody' do
        expect(page).to have_no_content '2015'
      end
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::SchoolCalendarSteps
end
