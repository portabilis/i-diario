# encoding: utf-8
module Turnip
  module DisciplinaryIncidentsSteps
    step "que possuo alunos vinculados" do
      expect(Student.count).to eq 3
    end

    step "acesso a página de ocorrências disciplinares" do
      VCR.use_cassette('disciplinary_incidents') do
        within "#left-panel" do
          click_on '***REMOVED***'
        end
      end
    end

    step 'verei as ocorrências de meus alunos' do
      within "table#resources" do
        expect(page).to have_content "Bagunça Em Sala De Aula"
        expect(page).to have_content "10/09/2014 10:07:00"
        expect(page).to have_content "teste"
      end
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::DisciplinaryIncidentsSteps
end
