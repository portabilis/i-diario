# encoding: utf-8
module Turnip
  module RolesSteps
    step "que acesso a listagem de permissões" do
      click_***REMOVED*** 'Configurações > Permissões'
    end

    step 'eu entrar no formulário de nova permissão' do
      click_on "Novo"
    end

    step 'poderei cadastrar uma nova permissão' do
      fill_in "Nome", with: "Secretaria"
      fill_in_select2 "Tipo", with: "employee"

      click_on "Salvar"

      expect(page).to have_content "Permissão foi criada com sucesso."
    end

    step 'que existe uma permissão cadastrada' do
      click_***REMOVED*** 'Configurações > Permissões'

      within :xpath, '//table/tbody/tr[position()=1]' do
        expect(page).to have_content 'Administrador'
      end
    end

    step 'entro na tela de edição desta permissão' do
      within :xpath, '//table/tbody/tr[position()=1]' do
        click_on 'Editar'
      end
    end

    step 'poderei permitir acesso às funcionalidades' do
      expect(page).to have_field "Nome", with: "Administrador"

      within "tr#role-users" do
        expect(page).to have_content "Usuários"
        expect(page).to have_select2_filled 'Permissão', with: 'Leitura/Escrita'
      end

      within "tr#role-unities" do
        expect(page).to have_content "Unidades"
        expect(page).to have_select2_filled 'Permissão', with: 'Leitura/Escrita'
      end

      within "tr#role-***REMOVED***" do
        expect(page).to have_content "***REMOVED***"
        expect(page).to have_select2_filled 'Permissão', with: 'Leitura/Escrita'
      end

      within "tr#role-***REMOVED***" do
        expect(page).to have_content "***REMOVED***"
        expect(page).to have_select2_filled 'Permissão', with: 'Sem acesso'

        fill_in_select2 "Permissão", with: "Leitura"
      end

      click_on 'Salvar'

      expect(page).to have_content 'Permissão foi alterada com sucesso.'

      within :xpath, '//table/tbody/tr[position()=1]' do
        expect(page).to have_content 'Administrador'
      end
    end

    step "que existem permissões cadastradas" do
      click_***REMOVED*** 'Configurações > Permissões'

      within :xpath, '//table/tbody/tr[position()=2]' do
        expect(page).to have_content 'Secretária'
      end
    end

    step "poderei excluir uma permissão" do
      within :xpath, '//table/tbody/tr[position()=2]' do
        expect(page).to have_content 'Secretária'

        click_on 'Excluir'
      end

      expect(page).to have_content "Permissão foi apagada com sucesso"

      expect(page).to have_no_content 'Secretária'
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::RolesSteps
end
