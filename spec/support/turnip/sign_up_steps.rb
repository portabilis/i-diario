# encoding: utf-8
module Turnip
  module SignUpSteps
    step "que acesso a página de signup de pais" do
      visit root_path

      click_link 'Criar conta'

      expect(page).to have_content "Escolha seu perfil"

      click_on "Acesso pais"
    end

    step "informo os dados para o cadastro de pais" do
      VCR.use_cassette('signup_parent') do
        within "#tab1" do
          expect(page).to have_content "Passo 1 - Informações básicas"

          fill_mask "CPF", with: "729.785.662-21"
          fill_in "Código do aluno", with: "1931"

          sleep 2
        end
      end

      within "#tab2" do
        expect(page).to have_content "Passo 2 - Alunos"

        within "table" do
          within "tbody tr:nth-child(1)" do
            expect(page).to have_content "ADRIANO ROQUE"
            expect(page).to have_content "544"
          end

          within "tbody tr:nth-child(2)" do
            expect(page).to have_content "ABNER ROCHA"
            expect(page).to have_content "1931"
          end
        end
      end

      click_on "Próximo"

      within "#tab3" do
        expect(page).to have_content "Passo 3 - Cadastro do usuário"

        fill_mask "Celular", with: "(31) 94361177"
        fill_in 'E-mail', with: 'jane_doe@example.com'
        fill_in 'Senha', with: '11223344'
        fill_in 'Confirme a senha', with: '11223344'
      end

      click_on "Próximo"

      within "#tab4" do
        click_button 'Confirmar e acessar o sistema'
      end
    end

    step "deverei ser logado ao sistema" do
      expect(page).to have_text 'Bem-vindo! Você se registrou com sucesso.'
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::SignUpSteps
end
