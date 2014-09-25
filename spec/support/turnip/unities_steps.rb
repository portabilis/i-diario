# encoding: utf-8
module Turnip
  module UnitiesSteps
    step "que acesso a listagem de unidades" do
      click_***REMOVED*** 'Configurações > Unidades'
    end

    step 'eu entrar no formulário de nova unidade' do
      click_on "Novo"
    end

    step 'poderei cadastrar uma nova unidade' do
      fill_in "Nome", with: "Escola X"

      click_on "Salvar"

      expect(page).to have_content "Unidade foi criada com sucesso."
    end

    step 'que existe uma unidade cadastrada' do
      click_***REMOVED*** 'Configurações > Unidades'

      within :xpath, '//table/tbody/tr[position()=1]' do
        expect(page).to have_content 'Escola A'
      end
    end

    step 'entro na tela de edição desta unidade' do
      within 'table.table tbody' do
        click_on 'Editar'
      end
    end

    step 'poderei alterar seus dados' do
      fill_in 'Nome', with: 'Unidade Z'

      expect(page).to have_field "CEP", with: "32672-124"
      expect(page).to have_field "Rua", with: "Rua Goiania"
      expect(page).to have_field "Número", with: "54"
      expect(page).to have_field "Bairro", with: "Centro"
      expect(page).to have_field "Cidade", with: "Betim"
      expect(page).to have_select "Estado", selected: "Minas Gerais"
      expect(page).to have_field "País", with: "Brasil"

      click_on 'Salvar'

      expect(page).to have_content 'Unidade foi alterada com sucesso.'

      within :xpath, '//table/tbody/tr[position()=1]' do
        expect(page).to have_content 'Unidade Z'
      end
    end

    step "que existem unidades cadastradas" do
      click_***REMOVED*** 'Configurações > Unidades'

      within :xpath, '//table/tbody/tr[position()=1]' do
        expect(page).to have_content 'Escola A'
      end
    end

    step "poderei excluir uma unidade" do
      within :xpath, '//table/tbody/tr[position()=1]' do
        expect(page).to have_content 'Escola A'
        click_on 'Excluir'
      end

      expect(page).to have_content "Unidade foi apagada com sucesso"

      expect(page).to have_no_content 'Escola A'
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::UnitiesSteps
end
