# encoding: utf-8
module Turnip
  module UnitiesSteps
    step "que acesso a listagem de unidades" do
      click_link 'Unidades'
    end

    step 'eu entrar no formulário de nova unidade' do
      click_on "Novo"
    end

    step 'poderei cadastrar uma nova unidade' do
      fill_in "Nome", with: "Escola X"

      click_on "Salvar"

      expect(page).to have_content "Unidade criada com sucesso"
    end

    step 'que existe uma unidade cadastrada' do
      click_link 'Unidades'

      within :xpath, '//table/tbody/tr[position()=1]' do
        expect(page).to have_content 'Escola Y'
      end
    end

    step 'entro na tela de edição desta unidade' do
      within 'table.table tbody' do
        click_on 'Editar'
      end
    end

    step 'poderei alterar seus dados' do
      fill_in 'Nome', with: 'Unidade Z'

      click_on 'Salvar'

      expect(page).to have_content 'Unidade editada com sucesso'

      within "footer" do
        click_on 'Voltar'
      end

      within :xpath, '//table/tbody/tr[position()=1]' do
        expect(page).to have_content 'Unidade Z'
      end
    end

    step "poderei excluir esta unidade" do
      within :xpath, '//table/tbody/tr[position()=1]' do
        expect(page).to have_content 'Escola Y'
        click_on 'Excluir'
      end

      expect(page).to have_content "Unidade foi apagada com sucesso"

      expect(page).to have_no_content 'Escola Y'
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::UnitiesSteps
end
