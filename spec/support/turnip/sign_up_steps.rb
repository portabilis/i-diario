# encoding: utf-8
module Turnip
  module SignUpSteps
    step "que acesso a página de signup" do
      visit root_path

      click_link 'Criar conta'
    end

    step "realizo o cadastro de um novo usuário" do
      fill_in 'E-mail', with: 'jane_doe@example.com'
      fill_in 'Senha', with: '11223344'
      fill_in 'Confirme a senha', with: '11223344'

      click_button 'Cadastrar'
    end

    step "deverei ser logado ao sistema" do
      expect(page).to have_text 'Bem-vindo! Você se registrou com sucesso.'
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::SignUpSteps
end
