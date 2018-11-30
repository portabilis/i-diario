# encoding: utf-8
module Turnip
  module EntityConfigurationSteps
    step 'acesso as configurações da entidade' do
      click_menu 'Configurações > Entidade'
    end

    step 'poderei alterar informações da entidade' do
      fill_in 'Nome da entidade', with: 'Prefeitura municipal de Portabilis Tecnologia'
      fill_mask 'CEP', with: '88820-000'
      sleep 5.0
      fill_in 'Rua', with: 'Rua de Exemplo'
      fill_in 'Número', with: '11'
      fill_in 'Bairro', with: 'Bairro de Exemplo'
      fill_in 'Cidade', with: 'Içara'
      select 'Santa Catarina', from: 'Estado'
      fill_in 'País', with: 'Brasil'

      click_button 'Salvar'

      sleep 0.2
      wait_for(page).to have_content "Configurações da entidade foi alterada com sucesso."
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::EntityConfigurationSteps
end
