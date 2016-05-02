module Turnip
  module ObservationRecordReportSteps
    step 'eu entrar na tela do relatório de registro de observações' do
      click_***REMOVED*** 'Relatórios > Registro de observações'
    end

    step 'poderei imprimir o relatório de registro de observações' do
      fill_in_select2 'Turma', with: @classroom.id
      sleep 2
      fill_in_select2 'Disciplina', with: @discipline.id
      fill_mask 'Data inicial', with: '01/02/2016'
      fill_mask 'Data final', with: '29/02/2016'

      report_tab = page.window_opened_by do
        click_on 'Imprimir'
      end

      within_window(report_tab) do
        expect(page).not_to have_content('Por favor, verifique os campos obrigatórios e tente novamente.')
        expect(page).not_to have_content('Nenhum resultado foi encontrado para os dados informados')
      end
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::ObservationRecordReportSteps
end
