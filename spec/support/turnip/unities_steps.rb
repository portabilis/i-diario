# encoding: utf-8

module Turnip
  module UnitiesSteps
    step "que acesso a listagem de unidades" do
      click_menu 'Configurações > Unidades'
    end

    step 'eu entrar no formulário de nova unidade' do
      click_on "Nova unidade"
    end

    step 'poderei cadastrar uma nova unidade' do
      wait_for(page).to have_select2_filled 'Tipo de unidade', with: 'Unidade escolar'

      fill_in "Nome", with: "Escola Y"
      fill_in_select2 "Tipo de unidade", with: "school_unit"
      fill_mask 'CEP', with: '88820-000'
      sleep 5.0
      fill_in 'Rua', with: 'Rua de Exemplo'
      fill_in 'Número', with: '11'
      fill_in 'Bairro', with: 'Bairro de Exemplo'
      fill_in 'Cidade', with: 'Içara'
      select 'Santa Catarina', from: 'Estado'
      fill_in 'País', with: 'Brasil'

      click_button 'Salvar'

      sleep 0.2

      wait_for(page).to have_content "Unidade foi criada com sucesso."
    end

    step 'que existe uma unidade cadastrada' do
      click_menu 'Configurações > Unidades'

      within :xpath, '//table/tbody/tr[position()=2]' do
        wait_for(page).to have_content 'Escola A Unidade escolar'
      end
    end

    step 'entro na tela de edição desta unidade' do
      within 'table.table tbody' do
        click_on 'Editar'
      end
    end

    step 'poderei alterar os dados da unidade' do
      fill_in 'Nome', with: 'Unidade Z'

      wait_for(page).to have_field "CEP", with: "32672-124"
      wait_for(page).to have_field "Rua", with: "Rua Goiania"
      wait_for(page).to have_field "Número", with: "54"
      wait_for(page).to have_field "Bairro", with: "Centro"
      wait_for(page).to have_field "Cidade", with: "Betim"
      wait_for(page).to have_select "Estado", selected: "Minas Gerais"
      wait_for(page).to have_field "País", with: "Brasil"

      click_on 'Salvar'

      wait_for(page).to have_content 'Unidade foi alterada com sucesso.'

      within :xpath, '//table/tbody/tr[position()=3]' do
        wait_for(page).to have_content 'Unidade Z'
      end
    end

    step "que existem unidades cadastradas" do
      click_menu 'Configurações > Unidades'

      wait_for(page).to have_content 'Escola Z'
    end

    step "poderei excluir uma unidade" do
      wait_for(page).to have_content 'Escola Z'
      accept_alert { click_on 'Excluir Escola Z' }

      wait_for(page).to have_content "Unidade foi apagada com sucesso"

      wait_for(page).to have_no_content 'Escola Z'
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::UnitiesSteps
end
