module Turnip
  module ObservationDiaryRecordsSteps
    step 'que dou aula para uma turma com frequência por disciplina' do
      exam_rule = create(:exam_rule, frequency_type: FrequencyTypes::BY_DISCIPLINE)
      @classroom = create(
        :classroom,
        unity: @current_user.current_user_role.unity,
        exam_rule: exam_rule
      )
      @teacher_discipline_classroom = create(
        :teacher_discipline_classroom,
        classroom: @classroom,
        allow_absence_by_discipline: true,
      )
      @teacher = @teacher_discipline_classroom.teacher
      @discipline = @teacher_discipline_classroom.discipline

      @current_user.teacher = @teacher
      @current_user.save!
    end

    step 'que acesso a listagem do diário de observações' do
      click_***REMOVED*** 'Diário de observações'
    end

    step 'que existe um registro do diário de observações cadastrado' do
      @observation_diary_record = create(
        :observation_diary_record_with_notes,
        school_calendar: @school_calendar,
        teacher: @teacher,
        classroom: @classroom,
        discipline: @discipline,
        date: '16/02/2016'
      )

      click_***REMOVED*** 'Diário de observações'

      within :xpath, '//table/tbody/tr[position()=1]' do
        expect(page).to have_content @observation_diary_record.classroom
      end
    end

    step 'eu entrar no formulário de novo registro do diário de observações' do
      click_on 'Novo lançamento'
    end

    step 'eu entro na tela de edição deste registro do diário de observações' do
      within :xpath, '//table/tbody/tr[position()=1]' do
        click_on 'Editar'
      end
    end

    step 'poderei cadastrar um novo registro no diário de observações' do
      fill_in_select2 'Turma', with: @classroom.id
      sleep 2
      fill_in_select2 'Disciplina', with: @discipline.id
      fill_mask 'Data', with: '16/02/2016'

      click_on 'Adicionar observação'

      within '#observation-diary-record-notes tr.nested-fields' do
        fill_in 'Descrição', with: 'Exemplo de descrição'
      end

      click_on 'Salvar'

      expect(page).to have_content 'Registro do diário de observações foi criado com sucesso.'
    end

    step 'poderei atualizar os dados deste registro do diário de observações' do
      within '#observation-diary-record-notes tr.nested-fields' do
        fill_in 'Descrição', with: 'Novo exemplo de descrição'
      end

      click_on 'Salvar'

      expect(page).to have_content 'Registro do diário de observações foi alterado com sucesso.'
    end

    step 'poderei excluir este registro do diário de observações' do
      within :xpath, '//table/tbody/tr[position()=1]' do
        click_on 'Excluir'
      end

      expect(page).to have_content 'Registro do diário de observações foi apagado com sucesso.'
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::ObservationDiaryRecordsSteps
end
