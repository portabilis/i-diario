# encoding: utf-8
require 'spec_helper'

feature "SignUp" do
  fixtures :entities
  fixtures :users

  scenario 'sign in with invalid credentials' do
    visit root_path

    click_link 'Cadastrar'

    fill_in 'E-mail', with: 'jane_doe@example.com'
    fill_in 'Senha', with: '11223344'
    fill_in 'Confirme a senha', with: '11223344'

    click_button 'Cadastrar'

    expect(page).to have_content 'Bem-vindo! Você se registrou com sucesso.'
    expect(page).to have_content 'Educação Logado como jane_doe@example.com'
  end
end
