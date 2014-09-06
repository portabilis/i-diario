# encoding: utf-8
module Turnip
  module ProfileSteps
    step "acesso a página de perfis" do
      click_***REMOVED*** 'Configurações > Perfis de acesso'
    end

    step 'concedo uma permissão' do
      checkbox = "#{profiles(:student).id}_manage_profiles"

      expect(page).to have_unchecked_field checkbox

      # necessario pois o template do bootstrap esconde os checkboxes
      find_by_id(checkbox).trigger('click')
    end

    step 'verifico que a permissão está concedida' do
      checkbox = "#{profiles(:student).id}_manage_profiles"

      expect(page).to have_checked_field checkbox
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::ProfileSteps
end
