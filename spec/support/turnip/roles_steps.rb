# encoding: utf-8
module Turnip
  module RolesSteps
    step "que acesso a listagem de permissões" do
      click_menu 'Configurações > Permissões'
    end

    step 'eu entrar no formulário de nova permissão' do
      click_on "Nova permissão"
    end

    step 'poderei cadastrar uma nova permissão' do
      fill_in "Nome", with: "Secretaria"
      fill_in_select2 "Nível de acesso", with: "teacher"

      click_on "Salvar"

      wait_for(page).to have_content "Permissão foi criada com sucesso."
    end

    step 'que existe uma permissão cadastrada' do
      click_menu 'Configurações > Permissões'

      within :xpath, '//table/tbody/tr[position()=1]' do
        wait_for(page).to have_content 'Administrador'
      end
    end

    step 'entro na tela de edição desta permissão' do
      within :xpath, '//table/tbody/tr[position()=1]' do
        click_on 'Editar'
      end
    end

    step 'poderei permitir acesso às funcionalidades' do
      wait_for(page).to have_field "Nome", with: "Administrador"

      within "tr#role-users" do
        wait_for(page).to have_content "Usuários"
        wait_for(page).to have_select2_filled 'Permissão', with: 'Leitura/Escrita'
      end

      within "tr#role-unities" do
        wait_for(page).to have_content "Unidades"
        wait_for(page).to have_select2_filled 'Permissão', with: 'Leitura/Escrita'
      end

      click_on 'Salvar'

      wait_for(page).to have_content 'Permissão foi alterada com sucesso.'

      within :xpath, '//table/tbody/tr[position()=1]' do
        wait_for(page).to have_content 'Administrador'
      end
    end

    step "que existem permissões cadastradas" do
      click_menu 'Configurações > Permissões'

      within :xpath, '//table/tbody/tr[position()=3]' do
        wait_for(page).to have_content 'Secretária'
      end
    end

    step "poderei excluir uma permissão" do
      within :xpath, '//table/tbody/tr[position()=3]' do
        wait_for(page).to have_content 'Secretária'

        click_on 'Excluir'
      end

      wait_for(page).to have_content "Permissão foi apagada com sucesso"

      wait_for(page).to have_no_content 'Secretária'
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::RolesSteps
end
