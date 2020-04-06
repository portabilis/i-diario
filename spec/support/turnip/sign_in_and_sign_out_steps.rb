# encoding: utf-8
module Turnip
  module SignInAndSignOutSteps
    step "que acesso a página de login" do
      visit root_path
    end

    step "informo dados inválidos para login" do
      fill_in 'Informe o Nome de usuário, E-mail ou CPF', with: 'john_doe@example.com'
      fill_in 'Senha', with: 'wrong_password'

      click_button 'Acessar'
    end

    step "não conseguirei acessar o sistema" do
      wait_for(page).to have_content 'Email ou senha inválidos.'
    end

    step "informo o email para login" do
      fill_in 'Informe o Nome de usuário, E-mail ou CPF', with: 'john_doe@example.com'
      fill_in 'Senha', with: '12345678'

      click_button 'Acessar'
    end

    step "serei logado no sistema" do
      wait_for(page).to have_content 'Login realizado com sucesso.'
    end

    step "informo o usuário para login" do
      fill_in 'Informe o Nome de usuário, E-mail ou CPF', with: 'john_doe'
      fill_in 'Senha', with: '12345678'

      click_button 'Acessar'
    end

    step "informo o cpf para login" do
      fill_in 'Informe o Nome de usuário, E-mail ou CPF', with: '639.290.118-32'
      fill_in 'Senha', with: '12345678'

      click_button 'Acessar'
    end

    step "informo o cpf sem caracteres não numéricos para login" do
      fill_in 'Informe o Nome de usuário, E-mail ou CPF', with: '63929011832'
      fill_in 'Senha', with: '12345678'

      click_button 'Acessar'
    end

    step "que estou logado" do
      visit root_path

      fill_in 'Informe o Nome de usuário, E-mail ou CPF', with: 'john_doe@example.com'
      fill_in 'Senha', with: '12345678'

      click_button 'Acessar'

      wait_for(page).to have_content 'Login realizado com sucesso.'
    end

    step "poderei sair do sistema" do
      click_link 'sign_out'

      wait_for(page).to have_content "Caso você não possua login de acesso cadastre-se em 'Criar conta'."
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::SignInAndSignOutSteps
end
