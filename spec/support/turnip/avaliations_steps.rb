# encoding: utf-8

module Turnip
  module AvaliationsSteps
    step "que existem turmas com tipo de avaliação não numérica vinculadas ao professor logado" do
      exam_rule_with_concept_score_type = create(:exam_rule, score_type: ScoreTypes::CONCEPT)
      @classroom_with_concept_score_type = create(:classroom, exam_rule: exam_rule_with_concept_score_type)
      @teacher_discipline_classroom = create(:teacher_discipline_classroom, classroom: @classroom_with_concept_score_type)
      user = users(:john_doe)
      user.teacher = @teacher_discipline_classroom.teacher
      user.save
    end

    step "que acesso a listagem de avaliações" do
      click_***REMOVED*** 'Avaliações > Cadastro de avaliações'
    end

    step 'eu entrar no formulário de nova avaliação' do
      click_on "Novo cadastro de avaliação"
    end

    step 'selecionar uma turma com tipo de avaliação não numérica' do
      fill_in_select2 "Escola", with: @classroom_with_concept_score_type.unity.id
      expect(page).to have_content(@classroom_with_concept_score_type.unity.name)

      fill_in_select2 "Turma", with: @classroom_with_concept_score_type.id
      expect(page).to have_content(@classroom_with_concept_score_type.description)

      click_on "Salvar"
    end

    step 'devo visualizar uma mensagem de turma com tipo de avaliação não numérica' do
      expect(page).to have_content "o tipo de nota da regra de avaliação não é numérica"
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::AvaliationsSteps
end
