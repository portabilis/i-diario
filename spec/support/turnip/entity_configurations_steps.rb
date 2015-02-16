# encoding: utf-8
module Turnip
  module EntityConfigurationSteps 
    step 'acesso as configurações da entidade' do
      click_***REMOVED*** 'Configurações > Entidade'
    end

    step 'poderei alterar informações da entidade' do
      fill_in 'Nome da entidade', with: 'Prefeitura municipal de Portabilis Tecnologia'
      fill_mask 'CEP', with: '88801-000'
      fill_in 'Número', with: '11'

      click_button 'Salvar'

      expect(page).to have_content "Configurações da entidade foi alterada com sucesso."
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::EntityConfigurationSteps
end
