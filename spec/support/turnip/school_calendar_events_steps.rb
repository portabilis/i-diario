# encoding: utf-8
module Turnip
  module SchoolCalendarEventsSteps
    step 'que acesso a listagem de eventos do calendário letivo' do
      click_menu 'Calendário letivo'

      click_on 'Eventos'
    end

    step 'eu entrar no formulário de novo evento do calendário letivo' do
      click_on "Novo evento"
      sleep 1
      click_link "Da escola"
    end

    step 'poderei cadastrar um novo evento do calendário letivo' do
      fill_mask 'Data inicial', with: '25/12/2015'
      fill_mask 'Data final', with: '25/12/2015'
      fill_in 'Descrição', with: 'Natal'
      fill_in_select2 'Tipo', with: 'no_school'
      fill_in 'Legenda', with: 'E'

      page.execute_script %{
        $("#school_calendar_event_periods").select2('val', [1], true);
      }

      click_on 'Salvar'

      wait_for(page).to have_content 'Evento do calendário letivo foi criado com sucesso.'
    end

    step 'que existe um evento do calendário letivo cadastrada' do
      click_menu 'Calendário letivo'

      click_on 'Eventos'

      within '#resources > tbody > tr:nth-child(1)' do
        wait_for(page).to have_content "Ano Novo"
      end
    end

    step 'entro na tela de edição deste evento do calendário letivo' do
      within '#resources > tbody > tr:nth-child(1)' do
        click_on 'Editar'
      end
    end

    step 'poderei alterar os dados deste evento do calendário letivo' do
      fill_in 'Descrição', with: 'Ano Novo 2015'

      click_on 'Salvar'

      wait_for(page).to have_content 'Evento do calendário letivo foi alterado com sucesso.'
      wait_for(page).to have_content 'Ano Novo 2015'
    end

    step 'poderei excluir um evento do calendário letivo' do
      within '#resources > tbody > tr:nth-child(1)' do
        wait_for(page).to have_content "Ano Novo"
        accept_alert { click_link "Excluir" }
      end

      wait_for(page).to have_content 'Evento do calendário letivo foi apagado com sucesso'

      within '#resources > tbody' do
        wait_for(page).to have_no_content 'Ano Novo'
      end
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::SchoolCalendarEventsSteps
end
