# encoding: utf-8
module Turnip
  module GeneralConfigurationSteps
    step 'acesso as configurações gerais' do
      click_menu 'Configurações > Configurações gerais'
    end

    step 'poderei informar o nível de segurança da entidade' do
      select 'Avançado', from: 'Nível de segurança'

      click_button 'Salvar'

      wait_for(page).to have_content "Configurações gerais foi alterada com sucesso."
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::GeneralConfigurationSteps
end
