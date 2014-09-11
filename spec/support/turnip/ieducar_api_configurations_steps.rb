# encoding: utf-8
module Turnip
  module IeducarApiConfigurationsSteps
    step "acesso a edição da API" do
      click_***REMOVED*** 'Configurações > API de integração'
    end

    step 'poderei alterar a configuração da API' do
      fill_in 'URL do i-Educar', with: 'http://test.ieducar.com.br'
      fill_in 'Chave de acesso', with: '***REMOVED***'
      fill_in 'Chave secreta', with: '***REMOVED***'
      fill_in 'Código da instituição', with: '1'

      click_on 'Salvar'

      expect(page).to have_text 'API de integração foi alterada com sucesso.'

      expect(page).to have_field 'URL do i-Educar', with: 'http://test.ieducar.com.br'
      expect(page).to have_field 'Chave de acesso', with: '***REMOVED***'
      expect(page).to have_field 'Chave secreta', with: '***REMOVED***'
      expect(page).to have_field 'Código da instituição', with: '1'
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::IeducarApiConfigurationsSteps
end
