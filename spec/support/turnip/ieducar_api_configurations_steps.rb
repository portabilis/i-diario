# encoding: utf-8
module Turnip
  module IeducarApiConfigurationsSteps
    step "acesso a edição da API" do
      click_***REMOVED*** 'Configurações > Configurações da API'
    end

    step 'poderei alterar a configuração da API' do
      fill_in 'URL do i-Educar', with: 'https://ieducar.com.br'
      fill_in 'API token', with: 'asdqweas'
      fill_in 'API secret token', with: '123asdqweas'
      fill_in 'Código da instituição', with: '123'

      click_on 'Salvar'

      expect(page).to have_text 'Configuração da API foi alterada com sucesso.'

      expect(page).to have_field 'URL do i-Educar', with: 'https://ieducar.com.br'
      expect(page).to have_field 'API token', with: 'asdqweas'
      expect(page).to have_field 'API secret token', with: '123asdqweas'
      expect(page).to have_field 'Código da instituição', with: '123'
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::IeducarApiConfigurationsSteps
end
