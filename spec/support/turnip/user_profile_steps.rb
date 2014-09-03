# encoding: utf-8
module Turnip
  module UserProfileSteps
    step "que estou logado no sistema" do
      visit root_path

      fill_in 'Informe o Nome de usuário, E-mail, Celular ou CPF', with: 'john_doe@example.com'
      fill_in 'Senha', with: '12345678'

      click_button 'Acessar'

      expect(page).to have_content 'Login realizado com sucesso.'
    end

    step "acesso a página do meu perfil" do
      click_link 'Editar Perfil'
    end

    step "poderei editar minhas informações" do
      fill_in 'Nome', with: 'Jane'
      fill_in 'Sobrenome', with: 'Austen'
      fill_in 'Nome de usuário', with: 'jane_austen'
      #fill_in 'Celular', with: '(21) 1122-3344'
      #fill_in 'CPF', with: '123.456.789-10'
      check 'Autorizar envio de e-mails e mensagens sms'
      fill_in 'Senha atual', with: '12345678'

      click_button 'Alterar'

      expect(page).to have_content 'Você atualizou sua conta com sucesso.'

      click_link 'Editar Perfil'

      expect(page).to have_field 'Nome', with: 'Jane'
      expect(page).to have_field 'Sobrenome', with: 'Austen'
      expect(page).to have_field 'Nome de usuário', with: 'jane_austen'
      #expect(page).to have_field 'Celular', with: '(21) 1122-3344'
      #expect(page).to have_field 'CPF', with: '123.456.789-10'
      expect(page).to have_checked_field 'Autorizar envio de e-mails e mensagens sms'
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::UserProfileSteps
end
