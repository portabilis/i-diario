# encoding: utf-8
module Turnip
  module UserSteps
    step "que existem usuários com acesso pendente" do
    end

    step "que acesso a listagem de usuários" do
      click_menu 'Configurações > Usuários'
    end

    step "eu entrar no formulário de um usuário pendente" do
      wait_for(page).to have_content 'Usuários'

      within :xpath, '//table/tbody/tr[position()=2]' do
        wait_for(page).to have_content 'Mary Jane'
        wait_for(page).to have_content 'Pendente'

        click_on "Editar"
      end
    end

    step "poderei liberar o acesso deste usuário" do
      wait_for(page).to have_field 'Nome', with: 'Mary'
      wait_for(page).to have_field 'Sobrenome', with: 'Jane'
      wait_for(page).to have_field 'E-mail', with: 'mary_jane@example.com'

      fill_in_select2 'Status', with: 'Ativado'

      fill_autocomplete 'Aluno', with: 'Bruce Wayne'

      click_on 'Salvar'

      # TODO ajustar
      #wait_for(page).to have_content 'Usuário foi alterado com sucesso.'
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::UserSteps
end
