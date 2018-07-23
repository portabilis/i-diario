# encoding: utf-8
module Turnip
  module UserProfileSteps
    step "acesso a página do meu perfil" do
      within "#left-panel" do
        click_on 'Meu perfil'
      end
    end

    step "poderei editar minhas informações" do
      # fill_in 'Nome', with: 'Jane'
      # fill_in 'Sobrenome', with: 'Austen'
      # fill_in 'Nome de usuário', with: 'jane_austen'
      # fill_in 'Celular', with: '(21) 1122-3344'
      # fill_in 'CPF', with: '123.456.789-10'
      # fill_in 'Senha atual', with: '12345678'
      #
      # find(:css, "#user_receive_news").set(false)
      # # uncheck "user_receive_news"
      #
      # click_button 'Alterar'
      #
      # wait_for(page).to have_content 'Conta atualizada com sucesso.'
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::UserProfileSteps
end
