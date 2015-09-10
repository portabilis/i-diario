module Turnip
  module TestSettingsSteps
    step 'que acesso a listagem de configuração de avaliação' do
      click_***REMOVED*** 'Configurações > Avaliações'
    end

    step 'eu entrar no formulário de nova configuração de avaliação' do
      click_on "Nova configuração"
    end

    step 'poderei cadastrar uma nova configuração de avaliação' do
      fill_in_select2 'Tipo', with: 'general'
      fill_in 'Ano', with: '2010'
      fill_in 'Nota máxima', with: '10'
      fill_in 'Número de casas decimais', with: '2'

      click_on 'Salvar'

      expect(page).to have_content 'Configuração de avaliação foi criada com sucesso.'
    end

    step 'que existe uma configuração de avaliação cadastrada' do
      click_***REMOVED*** 'Configurações > Avaliações'

      within '#resources > tbody > tr:nth-child(2)' do
        expect(page).to have_content 'Geral 2014 - 10 2 Não'
      end
    end

    step 'entro na tela de edição desta configuração de avaliação' do
      within '#resources > tbody > tr:nth-child(2)' do
        click_on 'Editar'
      end
    end

    step 'poderei alterar os dados desta configuração de avaliação' do
      fill_in 'Ano', with: '2020'

      click_on 'Salvar'

      expect(page).to have_content 'Configuração de avaliação foi alterada com sucesso.'
      expect(page).to have_content '2020'
    end

    step 'poderei excluir uma configuração de avaliação' do
      within '#resources > tbody > tr:nth-child(2)' do
        expect(page).to have_content 'Geral 2014 - 10 2 Não'
        click_link "Excluir"
      end

      expect(page).to have_content 'Configuração de avaliação foi apagada com sucesso'
      expect(page).to have_no_content 'Geral 2014 - 10 2 Não'
    end

    step 'cadastrar uma nova configuração de avaliação com avaliações fixadas e desmembráveis' do
      fill_in_select2 'Tipo', with: 'general'
      fill_in 'Ano', with: '2010'
      fill_in 'Nota máxima', with: '10'
      fill_in 'Número de casas decimais', with: '2'

      # Clica no checkbox 'Fixar avaliações'
      find(:css, '#test_setting_fix_tests').trigger('click')

      click_on 'Adicionar avaliação'

      within '#test-settings-tests > tr:nth-child(2)' do
        fill_in 'Avaliação', with: 'Avaliação 01'
        fill_in 'Peso', with: '10,00'

        # Clica no checbox 'Permitir desmembrar'
        find(:css, '[id*=_allow_break_up]').trigger('click')
      end

      click_on 'Salvar'
    end

    step 'devo visualizar uma mensagem de configuração de avaliação cadastrada com sucesso' do
      expect(page).to have_content 'Configuração de avaliação foi criada com sucesso.'
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::TestSettingsSteps
end
