# encoding: utf-8
require 'spec_helper'

feature "SignInAndSignOut" do
  fixtures :entities
  fixtures :users

  scenario 'sign in with invalid credentials' do
    visit root_path

    fill_in 'Informe o Nome de usuário, E-mail, Celular ou CPF', with: 'john_doe@example.com'
    fill_in 'Senha', with: 'wrong_password'

    click_button 'Acessar'

    expect(page).to have_content 'Email ou senha inválidos.'
  end

  scenario 'sign in with email' do
    visit root_path

    fill_in 'Informe o Nome de usuário, E-mail, Celular ou CPF', with: 'john_doe@example.com'
    fill_in 'Senha', with: '12345678'

    click_button 'Acessar'

    expect(page).to have_content 'Login realizado com sucesso.'
  end

  scenario 'sign in with login' do
    visit root_path

    fill_in 'Informe o Nome de usuário, E-mail, Celular ou CPF', with: 'john_doe'
    fill_in 'Senha', with: '12345678'

    click_button 'Acessar'

    expect(page).to have_content 'Login realizado com sucesso.'
  end

  scenario 'sign in with phone' do
    visit root_path

    fill_in 'Informe o Nome de usuário, E-mail, Celular ou CPF', with: '(11) 9988-7766'
    fill_in 'Senha', with: '12345678'

    click_button 'Acessar'

    expect(page).to have_content 'Login realizado com sucesso.'
  end

  scenario 'sign in with cpf' do
    visit root_path

    fill_in 'Informe o Nome de usuário, E-mail, Celular ou CPF', with: '639.290.118-32'
    fill_in 'Senha', with: '12345678'

    click_button 'Acessar'

    expect(page).to have_content 'Login realizado com sucesso.'
  end

  scenario 'sign out' do
    visit root_path

    fill_in 'Informe o Nome de usuário, E-mail, Celular ou CPF', with: 'john_doe@example.com'
    fill_in 'Senha', with: '12345678'

    click_button 'Acessar'

    expect(page).to have_content 'Login realizado com sucesso.'

    click_link 'Sair'

    expect(page).to have_content 'Você precisa registrar-se ou fazer login para continuar.'
  end
end
