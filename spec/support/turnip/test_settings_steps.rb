# encoding: utf-8
module Turnip
  module TestSettingsSteps
    step 'que acesso a listagem de configuração de avaliação' do
      click_***REMOVED*** 'Configurações > Avaliação'
    end

    step 'eu entrar no formulário de nova configuração de avaliação' do
      click_on "Nova configuração"
    end

    step 'poderei cadastrar uma nova configuração de avaliação' do
      fill_in 'Ano', with: '2010'

      click_on 'Salvar'

      expect(page).to have_content 'Configuração de avaliação foi criada com sucesso.'
    end

    step 'que existe uma configuração de avaliação cadastrada' do
      click_***REMOVED*** 'Configurações > Avaliação'

      within '#resources > tbody > tr:nth-child(1)' do
        expect(page).to have_content "2015 Sim"
      end
    end

    step 'entro na tela de edição desta configuração de avaliação' do
      within '#resources > tbody > tr:nth-child(1)' do
        click_on 'Editar'
      end
    end

    step 'poderei alterar os dados desta configuração de avaliação' do
      fill 'Ano', with: '2020'

      click_on 'Salvar'

      expect(page).to have_content 'Configuração de avaliação foi alterada com sucesso.'
      expect(page).to have_content '2020'
    end

    step 'poderei excluir uma configuração de avaliação' do
      within '#resources > tbody > tr:nth-child(1)' do
        expect(page).to have_content "2015 Sim"
        click_link "Excluir"
      end

      expect(page).to have_content 'Configuração de avaliação foi apagada com sucesso'
      expect(page).to have_no_content '2015 Sim'
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::TestSettingsSteps
end
