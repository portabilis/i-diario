module Turnip
  module AvaliationsSteps
    step 'que existem turmas com tipo de avaliação númerica vinculadas ao professor logado' do
      exam_rule_with_numeric_score_type = create(:exam_rule, score_type: ScoreTypes::NUMERIC)
      @classroom_with_numeric_score_type = create(:classroom, exam_rule: exam_rule_with_numeric_score_type)
      @teacher_discipline_classroom = create(:teacher_discipline_classroom, classroom: @classroom_with_numeric_score_type)
      user = users(:john_doe)
      user.teacher = @teacher_discipline_classroom.teacher
      user.save
    end

    step 'que existem turmas com tipo de avaliação não numérica vinculadas ao professor logado' do
      exam_rule_with_concept_score_type = create(:exam_rule, score_type: ScoreTypes::CONCEPT)
      @classroom_with_concept_score_type = create(:classroom, exam_rule: exam_rule_with_concept_score_type)
      @teacher_discipline_classroom = create(:teacher_discipline_classroom, classroom: @classroom_with_concept_score_type)
      user = users(:john_doe)
      user.teacher = @teacher_discipline_classroom.teacher
      user.save
    end

    step 'que existe uma configuração de avaliação com avaliações fixas e que não permitem desmembrar' do
      # TODO: Refatorar
      TestSettingTest.delete_all
      TestSetting.delete_all
      @test_setting = FactoryGirl.build(:test_setting, year: 2015, maximum_score: 10, fix_tests: true)
      @test = @test_setting.tests.build(FactoryGirl.attributes_for(:test_setting_test, weight: @test_setting.maximum_score, allow_break_up: false))
      @test_setting.save
    end

    step 'que existe uma configuração de avaliação com avaliações fixas e que permitem desmembrar' do
      # TODO: Refatorar
      TestSettingTest.delete_all
      TestSetting.delete_all
      @test_setting = FactoryGirl.build(:test_setting, year: 2015, maximum_score: 10, fix_tests: true)
      @test = @test_setting.tests.build(FactoryGirl.attributes_for(:test_setting_test, weight: @test_setting.maximum_score, allow_break_up: true))
      @test_setting.save
    end

    step 'que acesso a listagem de avaliações' do
      click_***REMOVED*** 'Avaliações > Cadastro de avaliações'
    end

    step 'eu entrar no formulário de nova avaliação' do
      click_on "Novo cadastro de avaliação"
    end

    step 'cadastrar uma nova avaliação com avaliações que não permite desmembrar' do
      fill_in_select2 'Escola', with: @classroom_with_numeric_score_type.unity.id
      sleep 1
      fill_in_select2 'Turma', with: @classroom_with_numeric_score_type.id
      sleep 1
      fill_in_select2 'Disciplina', with: @teacher_discipline_classroom.discipline.id
      fill_mask 'Data da avaliação', with: '26/02/2015'

      # TODO: find a better solution
      page.execute_script %{
        $("#avaliation_classes").select2('val', [1], true);
      }

      fill_in_select2 'Tipo de avaliação', with: @test.id

      expect(page).to_not have_field('Peso')

      click_on "Salvar"
    end

    step 'cadastrar uma nova avaliação com avaliações que permite desmembrar' do
      fill_in_select2 'Escola', with: @classroom_with_numeric_score_type.unity.id
      sleep 1
      fill_in_select2 'Turma', with: @classroom_with_numeric_score_type.id
      sleep 1
      fill_in_select2 'Disciplina', with: @teacher_discipline_classroom.discipline.id
      fill_mask 'Data da avaliação', with: '26/02/2015'

      # TODO: find a better solution
      page.execute_script %{
        $("#avaliation_classes").select2('val', [1], true);
      }

      fill_in_select2 'Tipo de avaliação', with: @test.id
      fill_in 'Descrição', with: 'Prova'
      fill_in 'Peso', with: 5

      click_on "Salvar"
    end

    step 'selecionar uma turma com tipo de avaliação não numérica' do
      fill_in_select2 "Escola", with: @classroom_with_concept_score_type.unity.id
      using_wait_time 10 do
        expect(page).to have_content(@classroom_with_concept_score_type.unity.name)
      end

      sleep 1

      fill_in_select2 "Turma", with: @classroom_with_concept_score_type.id
      using_wait_time 10 do
        expect(page).to have_content(@classroom_with_concept_score_type.description)
      end

      click_on "Salvar"
    end

    step 'devo visualizar uma mensagem de avaliação cadastrada com sucesso' do
      expect(page).to have_content 'Cadastro de avaliação foi criado com sucesso.'
    end

    step 'devo visualizar uma mensagem de turma com tipo de avaliação não numérica' do
      expect(page).to have_content "o tipo de nota da regra de avaliação não é numérica"
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::AvaliationsSteps
end
